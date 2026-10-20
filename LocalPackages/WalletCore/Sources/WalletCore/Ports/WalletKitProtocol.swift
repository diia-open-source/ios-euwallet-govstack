//
//  WalletKitProtocol.swift
//

import Foundation
import WalletDomainModels

/// Domain-facing port for the EUDI wallet kit.
///
/// Features depend on this protocol; the concrete `WalletKitController` (which imports EudiWalletKit / OpenID4VCI / WalletStorage / Mdoc* / StatiumSwift) is the only implementor and lives in WalletEngine.
/// The host registers the instance via `WalletDependencies.setWalletController(_:)` at app launch; the protocol itself stays in WalletCore so feature SPMs can keep importing it without seeing the SDK.
///
/// All signatures use domain types (`IssuanceOffer`, `IssuanceResult`, `Credential`, `WalletAvailableDocument`, `DocumentCredentialStatus`, `DeferredPollOutcome`).
/// No SDK types may appear here.
public protocol WalletKitProtocol {
    var isStorageEmpty: Bool { get }
    var isWalletActivated: Bool { get }
    func resolveOfferUrlDocTypes(offerUri: String) async throws -> IssuanceOffer
    func issueDocument(issuerId: String, identifier: String) async throws -> IssuanceResult
    func issueDocuments(forOffer offer: IssuanceOffer, txCodeValue: String?) async throws -> [IssuanceResult]
    func resumePendingIssuance(webUrl: String) async throws -> IssuanceResult

    func loadDocuments() async throws
    func fetchDocuments(with type: String) -> [Credential]
    /// Issued documents only.
    /// Use `fetchAllDocumentsIncludingDeferred()` if callers need to dedup against in-flight deferred docs as well.
    func fetchAllDocuments() -> [Credential]
    func fetchAllDocumentsIncludingDeferred() -> [Credential]
    func fetchDocument(with id: String) -> Credential?
    func fetchAvailableDocumentTypes() async throws -> [WalletAvailableDocument]
    func clearAllDocuments() async throws
    func deleteDocuments(with docType: String) async throws
    func deleteDocument(with id: String) async throws

    // Deferred-issuance flow (OID4VCI §9): the issuer accepts a credential request but defers issuance, and the wallet polls a deferred endpoint until the credential becomes available, fails, or expires.
    func fetchDeferredDocuments() -> [Credential]
    func deleteDeferredDocument(with id: String) async throws
    func requestDeferredIssuance(forCredentialId id: String) async throws -> Credential
    func requestDeferredIssuanceForAll() async -> DeferredPollOutcome

    // Document status checking
    func checkDocumentStatus(for credential: Credential) async -> DocumentCredentialStatus
    func checkAllDocumentsStatus() async -> [String: DocumentCredentialStatus]
}
