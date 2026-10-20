//
//  WalletError+Domain.swift
//

import Foundation
import WalletCore
import WalletDomainModels
import EudiWalletKit

/// Internal converter from the upstream SDK error type to the WalletCore-domain wrapper.
///
/// Lives inside WalletCore so the upstream `WalletError` symbol never escapes the module boundary.
/// Session managers call this at the point where they hand an error to the delegate.
internal extension WalletError {
    /// Map the upstream `WalletError` to `PresentationError`, preserving description, the structured `code` and the `context` payload.
    func toDomainPresentationError() -> PresentationError {
        let message = errorDescription ?? description
        let mappedCode = code.flatMap(PresentationError.Code.init(_:)) ?? PresentationError.Code.inferred(fromDescription: message)
        return PresentationError(
            description: message,
            code: mappedCode,
            context: context
        )
    }
}

private extension PresentationError.Code {
    /// Recover a structured code from the SDK's free-text error when no upstream `WalletError.Code` was supplied.
    ///
    /// The OpenID4VP reader-auth chain failure is thrown as `ValidationError.validationError("Could not trust certificate chain")` (eudi-lib-ios-siop-openid4vp-swift `AccessValidator`) and reaches us wrapped as a plain description with no code. Substring-matching is the only available signal.
    ///
    /// TEMPORARY: matching on the SDK's fixed English text is brittle (breaks if the SDK rewords or localizes the message) and is only a stopgap.
    /// Once the SDK surfaces a structured `WalletError.Code` for these cases, drop the substring checks here and map the upstream code in the table below instead.
    static func inferred(fromDescription description: String?) -> PresentationError.Code? {
        guard let description else { return nil }
        if description.contains("Could not trust certificate chain") {
            return .readerNotTrusted
        }
        // BLE proximity surfaces a "verifier requested a document the wallet doesn't hold" as a plain NSError with no upstream code (eudi-lib-ios-wallet-kit `BlePresentationService`, `isValidRequest == false`), so it's inferred from the SDK's fixed English message.
        if description.contains("not available in your EUDI Wallet") {
            return .credentialNotFound
        }
        // OpenID4VP resolution throws a structured `claimNotFound` error, but `PresentationSession.receiveRequest()` flattens it in its catch block (`setError(error.localizedDescription)`), discarding both `code` and `context` and leaving only the English description.
        // Recover the code from that text so downstream gates still fire — notably the remote "required document is missing" mapping when the SDK has filtered out an expired document.
        if description.contains("Claim not found") {
            return .claimNotFound
        }
        return nil
    }
}

/// Sealed mapping table from upstream `WalletError.Code` to the WalletCore-domain code.
///
/// Kept inside WalletCore so adding a new upstream case requires touching only this file plus the public `PresentationError.Code` enum.
internal extension PresentationError.Code {
    init?(_ upstream: WalletError.Code) {
        switch upstream {
        case .claimNotFound: self = .claimNotFound
        case .credentialNotFound: self = .credentialNotFound
        case .claimValueMismatch: self = .claimValueMismatch
        case .claimSetNotSatisfied: self = .claimSetNotSatisfied
        case .credentialSetNotSatisfied: self = .credentialSetNotSatisfied
        case .dcqlQueryNotSatisfied: self = .dcqlQueryNotSatisfied
        case .bleNotAuthorized: self = .bleNotAuthorized
        case .bleNotSupported: self = .bleNotSupported
        case .noDocumentsAvailable: self = .noDocumentsAvailable
        case .issuerNotRegistered: self = .issuerNotRegistered
        }
    }
}
