//
//  WalletConfiguration.swift
//

import Foundation

public struct WalletConfiguration: Codable {
    public let issuers: [IssuerConfig]
    public let verifierReaderTrustRoots: [String]
    public let walletProviderBaseURL: String
    public let clientId: String
    public let authFlowRedirectionURI: String

    public struct IssuerConfig: Codable {
        public let host: String
        public let displayPriority: Int
        public let metadataTrustRoots: [String]
    }
}

extension WalletConfiguration {
    private static var _shared: WalletConfiguration?

    /// The active deployment configuration.
    /// Must be set via ``configure(_:)`` before any wallet code reads it; reads before configuration crash by design (missing config is a packaging error, not a runtime condition).
    public static var shared: WalletConfiguration {
        guard let value = _shared else {
            fatalError("WalletConfiguration.shared accessed before WalletConfiguration.configure(_:) was called — bootstrap the wallet config at app launch.")
        }
        return value
    }

    /// Install the deployment configuration. Call once at app startup, before any wallet code runs.
    public static func configure(_ value: WalletConfiguration) {
        _shared = value
    }

    public func issuer(forHost host: String) -> IssuerConfig? {
        issuers.first { $0.host == host }
    }

    public var issuerHosts: [String] {
        issuers.map(\.host)
    }
}
