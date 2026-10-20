//
//  WalletKitController.swift
//

import Foundation
import WalletCore
import WalletDomainModels
import OpenID4VCI
import EudiWalletKit
import WalletStorage
import MdocDataModel18013
import MdocSecurity18013
import StatiumSwift

public final class WalletKitController: WalletKitProtocol {

    public static let instance = WalletKitController()

    private let configLogic: WalletKitConfig
    private let wallet: EudiWallet

    /// Round-trip cache: maps an offer URI to the upstream `OfferedIssuanceModel` returned by `wallet.resolveOfferUrlDocTypes(...)`.
    /// `issueDocuments(forOffer:txCodeValue:)` looks this up so we don't have to carry the SDK type on the domain `IssuanceOfferedDocument`. On a miss (e.g. process restart between resolve and issue), the issue path transparently re-resolves and repopulates the entry.
    /// Guarded by `offerCacheLock` because controller methods are called from arbitrary Task contexts.
    private let offerCacheLock = NSLock()
    private var resolvedOffers: [String: OfferedIssuanceModel] = [:]

    private func cacheOffer(_ model: OfferedIssuanceModel, for uri: String) {
        offerCacheLock.lock(); defer { offerCacheLock.unlock() }
        resolvedOffers[uri] = model
    }

    private func cachedOffer(for uri: String) -> OfferedIssuanceModel? {
        offerCacheLock.lock(); defer { offerCacheLock.unlock() }
        return resolvedOffers[uri]
    }
    
    public var isStorageEmpty: Bool {
        return wallet.storage.docModels.isEmpty
    }
    
    /// Return 'false' if no documents have been uploaded from storage.
    public var isWalletActivated: Bool {
        return WalletDocumentType.allPidTypes.contains { type in
            !fetchDocuments(with: type.rawValue).isEmpty
        }
    }
    
    private init(configLogic: WalletKitConfig = WalletKitConfig()) {
        self.configLogic = configLogic
        
        guard let walletKit = try? EudiWallet(
          eudiWalletConfig: EudiWalletConfiguration(
            serviceName: configLogic.serviceName,
            userAuthenticationRequired: configLogic.userAuthenticationRequired,
            trustedReaderRootCertificates: configLogic.trustedReaderRoots
          ),
          openID4VpConfig: configLogic.vpConfig,
          openID4VciConfigurations: configLogic.vciConfig,
          networking: URLSession.shared,
          transactionLogger: WalletKitTransactionLoggerBridge(store: WalletDependencies.transactionLogStore)
        ) else {
          fatalError("Unable to Initialize WalletKit")
        }
        
        wallet = walletKit
    }
    
    public func resolveOfferUrlDocTypes(offerUri: String) async throws -> IssuanceOffer {
        configLogic.trustFailureRecorder.reset()
        do {
            let upstream = try await wallet.resolveOfferUrlDocTypes(offerUri: offerUri, authFlowRedirectionURI: configLogic.authFlowRedirectionURI)
            cacheOffer(upstream, for: offerUri)
            return upstream.toDomainOffer(uri: offerUri)
        } catch {
            throw mapIssuerTrustFailure(error)
        }
    }

    /// If the certificate validator rejected the issuer's signed metadata during the just-completed SDK call, surface a typed `issuerNotTrusted` so the UI can show the dedicated alert. Otherwise pass the original error through unchanged.
    private func mapIssuerTrustFailure(_ error: Error) -> Error {
        configLogic.trustFailureRecorder.didRejectChain ? WalletDomainError.issuerNotTrusted : error
    }

    public func issueDocument(issuerId: String, identifier: String) async throws -> IssuanceResult {
        let documents = try await wallet.issueDocuments(
            issuerName: issuerId,
            docTypeIdentifiers: [.identifier(identifier)],
            credentialOptions: nil
        )
        guard let document = documents.first else {
            throw WalletDomainError.noDocumentsIssued
        }
        return document.toIssuanceResult()
    }

    public func issueDocuments(forOffer offer: IssuanceOffer, txCodeValue: String?) async throws -> [IssuanceResult] {
        //        let docTypes = docTypes.map { docType in
        //            let rule = configLogic.documentIssuanceConfig.rule(for: docType.documentTypeIdentifier)
        //            let credentialOptions: CredentialOptions = .init(credentialPolicy: rule.policy, batchSize: rule.numberOfCredentials)
        //            return docType.copy(credentialOptions: credentialOptions)
        //        }
        let upstream: OfferedIssuanceModel
        if let cached = cachedOffer(for: offer.uri) {
            upstream = cached
        } else {
            // Cache miss — happens if the wallet process was restarted between resolve and issue, or if the resolve happened in a previous controller lifetime. Re-resolve transparently and repopulate so the issue path uses the live `OfferedDocModel` collection.
            configLogic.trustFailureRecorder.reset()
            do {
                upstream = try await wallet.resolveOfferUrlDocTypes(offerUri: offer.uri, authFlowRedirectionURI: configLogic.authFlowRedirectionURI)
            } catch {
                throw mapIssuerTrustFailure(error)
            }
            cacheOffer(upstream, for: offer.uri)
        }
        let documents = try await wallet.issueDocumentsByOfferUrl(
            offerUri: offer.uri,
            docTypes: upstream.docModels,
            txCodeValue: txCodeValue
        )
        return documents.map { $0.toIssuanceResult() }
    }
    
    public func resumePendingIssuance(webUrl: String) async throws -> IssuanceResult {
        guard let compatibleUrl = webUrl.toCompatibleUrl() else {
            throw WalletDomainError.missingMetadata
        }
        guard let pendingDocument = wallet.storage.pendingDocuments.last else {
            throw WalletDomainError.missingMetadata
        }
        guard let metadata = DocMetadata(from: pendingDocument.metadata) else {
            throw WalletDomainError.missingMetadata
        }

        let credentialIssuerIdentifier = "https://\(metadata.credentialIssuerIdentifier)"

        let result = try await wallet.resumePendingIssuance(
            issuerName: credentialIssuerIdentifier,
            pendingDoc: pendingDocument,
            webUrl: compatibleUrl,
            credentialOptions: .init(credentialPolicy: .rotateUse, batchSize: 100)
        )
        return result.toIssuanceResult()
    }
    
    public func loadDocuments() async throws {
        try await wallet.loadAllDocuments()
    }
    
    public func fetchDocument(with id: String) -> WalletDomainModels.Credential? {
        wallet.storage.getDocumentModel(id: id)?.toDomainCredential()
    }

    public func fetchDocuments(with type: String) -> [WalletDomainModels.Credential] {
        return wallet.storage.docModels
            .filter({ $0.docType == type })
            .map { $0.toDomainCredential() }
    }

    public func fetchAllDocuments() -> [WalletDomainModels.Credential] {
        return wallet.storage.docModels.map { $0.toDomainCredential() }
    }

    public func fetchAllDocumentsIncludingDeferred() -> [WalletDomainModels.Credential] {
        return wallet.storage.docModels.map { $0.toDomainCredential() }
            + wallet.storage.deferredDocuments.map { $0.toDomainCredential() }
    }

    public func fetchDeferredDocuments() -> [WalletDomainModels.Credential] {
        return wallet.storage.deferredDocuments.map { $0.toDomainCredential() }
    }

    public func deleteDeferredDocument(with id: String) async throws {
        try await wallet.deleteDocument(id: id, status: .deferred)
    }

    public func requestDeferredIssuance(forCredentialId id: String) async throws -> WalletDomainModels.Credential {
        guard let doc = wallet.storage.deferredDocuments.first(where: { $0.id == id }) else {
            throw WalletDomainError.missingMetadata
        }
        guard let metadata = DocMetadata(from: doc.metadata) else {
            throw WalletDomainError.missingMetadata
        }
        let issuerName = metadata.credentialIssuerIdentifier
        let result = try await wallet.requestDeferredIssuance(
            issuerName: issuerName,
            deferredDoc: doc,
            credentialOptions: .init(credentialPolicy: .rotateUse, batchSize: 100)
        )
        if result.isDeferred {
            return result.toDomainCredential()
        }
        if let issued = wallet.storage.getDocumentModel(id: result.id) {
            return issued.toDomainCredential()
        }
        throw WalletDomainError.missingMetadata
    }

    public func requestDeferredIssuanceForAll() async -> DeferredPollOutcome {
        var issued: [String] = []
        var failed: [String] = []
        var stillDeferred: [String] = []

        for credential in fetchDeferredDocuments() {
            do {
                let result = try await requestDeferredIssuance(forCredentialId: credential.id)
                if result.isDeferred {
                    stillDeferred.append(credential.id)
                } else {
                    issued.append(result.id)
                }
            } catch {
                failed.append(credential.id)
            }
        }
        return DeferredPollOutcome(issuedIds: issued, failedIds: failed, stillDeferredIds: stillDeferred)
    }

    public func fetchAvailableDocumentTypes() async throws -> [WalletAvailableDocument] {
        let issuers = Array(Set(WalletConfiguration.shared.issuerHosts))
        let wallet = self.wallet

        // Best-effort fetch: each issuer is queried independently, and a failure
        // of one issuer (404, timeout, malformed metadata, etc.) does not prevent
        // the picker from rendering credentials returned by the other issuers.
        // The function only throws when every issuer fails — the presenter then
        // distinguishes "offline" vs "all unavailable" via ReachabilityHelper.
        let outcomes = await withTaskGroup(
            of: Result<[WalletAvailableDocument], Error>.self
        ) { group in
            for issuerName in issuers {
                group.addTask {
                    do {
                        let metadata = try await wallet.getIssuerMetadata(issuerName: issuerName)
                        let docs: [WalletAvailableDocument] = metadata.credentialsSupported.compactMap { credential in
                            switch credential.value {
                            case .msoMdoc(let config):
                                return WalletAvailableDocument(
                                    name: Self.displayName(
                                        from: config.credentialMetadata?.display,
                                        fallback: credential.key.value
                                    ),
                                    issuerId: issuerName,
                                    identifier: credential.key.value,
                                    docType: config.docType
                                )
                            case .sdJwtVc(let config):
                                guard let vct = config.vct else { return nil }
                                return WalletAvailableDocument(
                                    name: Self.displayName(
                                        from: config.credentialMetadata?.display,
                                        fallback: credential.key.value
                                    ),
                                    issuerId: issuerName,
                                    identifier: credential.key.value,
                                    docType: vct
                                )
                            default:
                                return nil
                            }
                        }
                        return .success(docs)
                    } catch {
                        return .failure(error)
                    }
                }
            }

            var collected: [Result<[WalletAvailableDocument], Error>] = []
            for await result in group {
                collected.append(result)
            }
            return collected
        }

        let documents = outcomes.compactMap { try? $0.get() }.flatMap { $0 }
        let errors = outcomes.compactMap { result -> Error? in
            if case .failure(let error) = result { return error }
            return nil
        }

        // Partial success: at least one issuer responded — render the picker
        // with whatever we received. Failures are silent in the UI.
        if !documents.isEmpty {
            return documents
        }

        // All issuers failed — surface the first error so the presenter's
        // ReachabilityHelper branch can decide between offline UI and error toast.
        // (If `errors` is empty the issuer list itself was empty — also a hard fail.)
        if let firstError = errors.first {
            throw firstError
        }
        throw NSError(
            domain: "WalletKitController",
            code: -1,
            userInfo: [NSLocalizedDescriptionKey: WalletStringKey.walletNoIssuersConfigured.localized()]
        )
    }

    /// Fetches raw storage documents (with full issuer metadata).
    /// Use this when you need access to `WalletStorage.Document` methods
    /// like `getClaimDisplayNames()` or `getDisplayName()`.
    public func fetchAllStorageDocuments() async throws -> [WalletStorage.Document] {
        return try await wallet.loadAllDocuments() ?? []
    }

    public func clearAllDocuments() async throws {
        try await wallet.deleteAllDocuments()
    }
    
    public func deleteDocuments(with docType: String) async throws {
        let documents = fetchDocuments(with: docType)
        for document in documents {
            try await wallet.deleteDocument(id: document.id, status: .issued)
        }
    }
    
    public func deleteDocument(with id: String) async throws {
        return try await wallet.deleteDocument(id: id, status: .issued)
    }
    
    // MARK: - Presentation
    public func startProximityPresentation() async -> PresentationSession {
        return await wallet.beginPresentation(flow: .ble)
    }
    
    public func startRemotePresentation(urlString: String) async -> PresentationSession {
        let data = urlString.data(using: .utf8) ?? Data()
        return await wallet.beginPresentation(flow: .openid4vp(qrCode: data))
    }
    
    // MARK: - Document Status Checking
    
    /// Check the revocation status of a single document
    public func checkDocumentStatus(for credential: WalletDomainModels.Credential) async -> DocumentCredentialStatus {
        guard let upstream = wallet.storage.docModels.first(where: { $0.id == credential.id }) else {
            return .unknown
        }
        guard let statusIdentifier = upstream.statusIdentifier else {
            return .valid
        }

        do {
            let status = try await wallet.getDocumentStatus(for: statusIdentifier)
            switch status {
            case .valid:
                return .valid
            case .invalid:
                return .revoked
            case .suspended:
                return .suspended
            case .applicationSpecific, .reserved:
                return .unknown
            }
        } catch {
            return .unknown
        }
    }
    
    /// Check the status of all documents in the wallet
    public func checkAllDocumentsStatus() async -> [String: DocumentCredentialStatus] {
        var results: [String: DocumentCredentialStatus] = [:]

        for credential in fetchAllDocuments() {
            let status = await checkDocumentStatus(for: credential)
            results[credential.id] = status
        }

        return results
    }
}

private extension WalletKitController {
    static func displayName(from displays: [Display]?, fallback: String) -> String {
        let currentLocaleIdentifier = Locale.current.identifier
        let currentLanguageCode = Locale.current.language.languageCode?.identifier

        return displays?.first(where: { $0.locale?.identifier == currentLocaleIdentifier })?.name
        ?? displays?.first(where: { display in
            guard let currentLanguageCode else { return false }
            return display.locale?.language.languageCode?.identifier == currentLanguageCode
        })?.name
        ?? displays?.first?.name
        ?? fallback
    }
}

public extension String {
    func toCompatibleUrl() -> URL? {
        guard let decoded = self.removingPercentEncoding else { return nil }
        return if let url = URL(string: decoded) {
            url
        } else if let encodedString = decoded.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed), let url = URL(string: encodedString) {
            url
        } else {
            nil
        }
    }
}
