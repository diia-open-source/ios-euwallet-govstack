//
//  PresentationError.swift
//

import Foundation

/// App-domain representation of an error surfaced during an EUDI presentation flow (BLE proximity or OpenID4VP remote).
///
/// Replaces direct use of the SDK's error type in downstream code.
/// The WalletCore boundary forbids any `import EudiWalletKit` outside this module, so this type is what flows through delegate callbacks into `WalletSharing` presenters.
///
/// When the SDK populates a structured `code` and `context`, presenters can read them programmatically — see `WalletErrorFormatter` for the canonical mapping.
public struct PresentationError: Error, Sendable, Hashable {
    /// Human-readable description from the SDK.
    public let description: String?

    /// Structured error category.
    /// `nil` for legacy errors that don't carry a structured code.
    public let code: Code?

    /// Additional context payload from the SDK. Known keys:
    /// - `"claimPath"` — populated for `.claimNotFound` / `.claimValueMismatch` / `.claimSetNotSatisfied`. Format: `"<namespace>/<claimKey>"` (mDoc) or `"<vct>/<claimKey>"` (SD-JWT).
    /// - `"docType"` — populated for `.credentialNotFound`. Raw docType / vct string.
    public let context: [String: String]

    public init(description: String?, code: Code? = nil, context: [String: String] = [:]) {
        self.description = description
        self.code = code
        self.context = context
    }

    /// Structured error categories surfaced by the SDK.
    ///
    /// When the SDK adds new codes, extend this enum to match — WalletCore is the only place that needs to know about the upstream surface, so the conversion table at the boundary is where the addition is recorded.
    public enum Code: String, Sendable, Hashable {
        /// The verifier requested a claim that is not present in the credential.
        /// Context contains `claimPath`.
        case claimNotFound
        /// The verifier requested a credential/document type that is not in the wallet.
        /// Context contains `docType`.
        case credentialNotFound
        /// The verifier requested a claim whose value does not match.
        /// Context contains `claimPath`.
        case claimValueMismatch
        /// No `claim_set` option could be satisfied.
        /// Context contains the first-missing `claimPath`.
        case claimSetNotSatisfied
        /// A required `credential_set` cannot be satisfied.
        case credentialSetNotSatisfied
        /// The DCQL query could not be satisfied (general).
        case dcqlQueryNotSatisfied
        /// Bluetooth is not authorized by the user.
        case bleNotAuthorized
        /// Bluetooth is not supported on this device.
        case bleNotSupported
        /// No documents available for presentation.
        case noDocumentsAvailable
        /// The issuer is not registered.
        case issuerNotRegistered
        /// The verifier's reader-auth certificate chain could not be trusted against the wallet's reader trust roots.
        /// The SDK surfaces this only as a free-text validation error during request resolution (no upstream code), so it's inferred at the WalletCore boundary — see `WalletError.toDomainPresentationError()`.
        case readerNotTrusted
    }
}
