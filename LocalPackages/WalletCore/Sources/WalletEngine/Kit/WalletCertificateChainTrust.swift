//
//  WalletCertificateChainTrust.swift
//

import Foundation
import WalletCore
import WalletDomainModels
import Security
import OpenID4VCI
import MdocSecurity18013

/// Validates the certificate chain that signs an OpenID4VCI signed issuer metadata document, against the wallet's bundled trust roots.
///
/// Used as the trust anchor when an issuer's `OpenId4VciConfiguration.issuerMetadataPolicy` is set to `.preferSigned` or `.requireSigned`. The OpenID4VCI SDK invokes `isValid(chain:)` for every signed metadata response; the chain is the JWT's `x5c` header values (base64-encoded DER, leaf first).
///
/// Validation logic:
/// 1. Decode each base64 string into DER bytes
/// 2. Build SecCertificate objects
/// 3. Construct a SecTrust evaluation pinned to the wallet's bundled IACA roots
/// 4. Run iOS's standard X.509 chain validation (signature, validity period)
///
/// Note on trust anchor reuse: this currently uses the same `.der` bundle as `trustedReaderRootCertificates` (verifier reader-auth IACAs). In the EUDI reference architecture, issuer-metadata signing keys chain to the same roots. If/when those trust stores need to diverge, pass a separate roots array via the initializer.
final class WalletCertificateChainTrust: CertificateChainTrust {
    private let trustedRootCertificates: [SecCertificate]
    private let failureRecorder: IssuerTrustFailureRecorder?

    /// - Parameters:
    ///   - trustedRoots: The wallet's bundled trust roots for issuer-metadata signing, as `[x5chain]` from `WalletKitConfig.issuerMetadataRoots(for:)`. Each entry is treated as a chain whose final element is the root anchor.
    ///   - failureRecorder: Notified whenever a chain is rejected, so the controller can translate the SDK's opaque throw into `WalletDomainError.issuerNotTrusted`.
    init(trustedRoots: [x5chain], failureRecorder: IssuerTrustFailureRecorder? = nil) {
        self.trustedRootCertificates = trustedRoots.compactMap { $0.last }
        self.failureRecorder = failureRecorder
    }

    func isValid(chain: [String]) -> Bool {
        let valid = evaluate(chain: chain)
        if !valid {
            failureRecorder?.recordRejection()
        }
        return valid
    }

    private func evaluate(chain: [String]) -> Bool {
        guard !chain.isEmpty else { return false }

        // Decode base64 → DER bytes → SecCertificate
        let certs = chain.compactMap { base64String -> SecCertificate? in
            guard let derData = Data(base64Encoded: base64String) else { return nil }
            return SecCertificateCreateWithData(nil, derData as CFData)
        }
        guard certs.count == chain.count else { return false }

        // Build SecTrust evaluation pinned to our bundled roots
        var trust: SecTrust?
        let policy = SecPolicyCreateBasicX509()
        guard SecTrustCreateWithCertificates(certs as CFArray, policy, &trust) == errSecSuccess,
              let trust else { return false }

        SecTrustSetAnchorCertificates(trust, trustedRootCertificates as CFArray)
        SecTrustSetAnchorCertificatesOnly(trust, true)

        var error: CFError?
        return SecTrustEvaluateWithError(trust, &error)
    }
}
