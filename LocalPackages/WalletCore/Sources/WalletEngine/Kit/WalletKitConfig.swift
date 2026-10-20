//
//  WalletKitConfig.swift
//

import Foundation
import WalletCore
import WalletDomainModels
import Security
import EudiWalletKit
import MdocSecurity18013
import OpenID4VCI

struct WalletKitConfig {
    var walletProviderBaseURL: URL {
        guard let url = URL(string: WalletConfiguration.shared.walletProviderBaseURL) else {
            fatalError("Invalid walletProviderBaseURL in wallet-config.json: \(WalletConfiguration.shared.walletProviderBaseURL)")
        }
        return url
    }

    var userAuthenticationRequired = false

    /// Shared across every per-issuer certificate validator. Reference type, so the implicit struct copies all observe the same instance — `WalletKitController` resets it before, and reads it after, each SDK resolve to detect issuer-trust failures.
    let trustFailureRecorder = IssuerTrustFailureRecorder()

    /// Returns a `.preferSigned` policy whose trust anchors are scoped to the given issuer. The wallet sends `Accept: application/jwt, application/json`, validates a JWT response against this issuer's roots when one is returned, and falls back to plain JSON otherwise. Switch to `.requireSigned(...)` for strict mode or `.ignoreSigned` to disable signed-metadata checks.
    private func issuerMetadataPolicy(for issuer: String) -> IssuerMetadataPolicy {
        .preferSigned(issuerTrust: .byCertificateChain(
            certificateChainTrust: WalletCertificateChainTrust(
                trustedRoots: issuerMetadataRoots(for: issuer),
                failureRecorder: trustFailureRecorder
            )
        ))
    }

    var vpConfig: OpenId4VpConfiguration {
      .init(clientIdSchemes: [.x509SanDns, .x509Hash])
    }

    var authFlowRedirectionURI: URL? {
        URL(string: WalletConfiguration.shared.authFlowRedirectionURI)
    }

    var keyAttestationConfig: KeyAttestationConfiguration {
        KeyAttestationConfiguration(
            walletAttestationsProvider: DefaultWalletAttestationsProvider(walletProviderBaseURL: walletProviderBaseURL)
        )
    }

    private func makeVciConfig(issuer: String) -> OpenId4VciConfiguration {
        // TODO: Wire `trustedIssuerCertificates:` (Issuer Document Trust — chain validation of SD-JWT VC `x5c` and mDoc MSO `x5chain` against an IACA root).
        // Blocked on two upstream prerequisites:
        //   1. EudiWalletKit v0.30.1 accepts `trustedIssuerCertificates` in `OpenId4VciConfiguration.init` but never stores or uses it (dead stub). Needs SDK fix to propagate the value into MSO/SD-JWT chain validation.
        //   2. bb-wallet-issuer must split its self-signed cert into IACA Root + Document Signer leaf (see info/final/eudi-trust-architecture-v3.md §9) — otherwise there's no valid chain to anchor to.
        // Until then, document signatures from issuers are accepted without chain validation.
        OpenId4VciConfiguration(
            credentialIssuerURL: "https://\(issuer)",
            clientId: WalletConfiguration.shared.clientId,
            keyAttestationsConfig: keyAttestationConfig,
            authFlowRedirectionURI: authFlowRedirectionURI,
            issuerMetadataPolicy: issuerMetadataPolicy(for: issuer)
        )
    }

    var vciConfig: [String: OpenId4VciConfiguration] {
        Dictionary(keepingFirst: WalletConfiguration.shared.issuers.map { issuer in
            (issuer.host, makeVciConfig(issuer: issuer.host))
        })
    }

    var serviceName: String {
        guard let identifier = Bundle.main.bundleIdentifier else {
            return "eudi.document.storage"
        }
        return "\(identifier).eudi.document.storage"
    }

    /// Trust anchors authorised to sign verifier reader-auth certificates during BLE/OpenID4VP presentations. The bb-wallet-issuer self-signed cert is intentionally NOT in this list — it's an issuer metadata-signing key, not a verifier CA.
    var trustedReaderRoots: [x5chain] {
        loadCerts(WalletConfiguration.shared.verifierReaderTrustRoots)
    }

    /// Trust anchors authorised to sign issuer metadata for the given issuer. Scoped per-issuer (configured in `wallet-config.json`) so that, e.g., the bb-wallet-issuer self-signed cert is only accepted for `bb-wallet-issuer.demo.ukrohost.com` and not for `issuer.eudiw.dev`.
    private func issuerMetadataRoots(for issuer: String) -> [x5chain] {
        guard let config = WalletConfiguration.shared.issuer(forHost: issuer) else {
            return []
        }
        return loadCerts(config.metadataTrustRoots)
    }

    private func loadCerts(_ names: [String]) -> [x5chain] {
        let chains: [x5chain] = names.compactMap { name -> x5chain? in
            guard let url = Bundle.main.url(forResource: name, withExtension: "der"),
                  let data = try? Data(contentsOf: url) else {
                return nil
            }
            guard let cert = SecCertificateCreateWithData(nil, data as CFData) else {
                return nil
            }
            return [cert]
        }
        return chains
    }
}
