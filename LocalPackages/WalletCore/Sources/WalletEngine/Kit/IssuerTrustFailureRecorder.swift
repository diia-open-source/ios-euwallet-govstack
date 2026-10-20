//
//  IssuerTrustFailureRecorder.swift
//

import Foundation

/// Bridges the synchronous, SDK-driven certificate-chain check (`WalletCertificateChainTrust.isValid`) back to the async issuance call that triggered it.
///
/// The OpenID4VCI SDK invokes our `CertificateChainTrust` deep inside `resolveOfferUrlDocTypes`, then — on a rejection — throws a generic `WalletError` whose underlying `CredentialIssuerMetadataError` is not `LocalizedError`, so its reason ("Failed to verify chain") never reaches us as inspectable text.
/// Rather than string-match the opaque error, `WalletCertificateChainTrust` records the rejection here, and `WalletKitController` resets-before / reads-after the SDK call to decide whether a thrown error was an issuer-trust failure.
///
/// A single recorder instance is shared by every per-issuer validator (held by `WalletKitConfig`), so the controller's reset/read brackets one resolve at a time. Issuance resolves are user-driven and serial in practice.
final class IssuerTrustFailureRecorder: @unchecked Sendable {
    private let lock = NSLock()
    private var didReject = false

    /// Clear the flag before an SDK call that may invoke the trust validator.
    func reset() {
        lock.lock(); defer { lock.unlock() }
        didReject = false
    }

    /// Called by `WalletCertificateChainTrust` whenever it rejects a chain.
    func recordRejection() {
        lock.lock(); defer { lock.unlock() }
        didReject = true
    }

    /// `true` if a chain was rejected since the last `reset()`.
    var didRejectChain: Bool {
        lock.lock(); defer { lock.unlock() }
        return didReject
    }
}
