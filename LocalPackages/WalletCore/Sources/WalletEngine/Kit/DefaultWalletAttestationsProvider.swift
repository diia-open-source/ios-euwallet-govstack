//
//  DefaultWalletAttestationsProvider.swift
//

import Foundation
import WalletCore
import WalletDomainModels
import EudiWalletKit
import JOSESwift

final class DefaultWalletAttestationsProvider: WalletAttestationsProvider {
    private let walletProviderBaseURL: URL
    private let session: URLSession

    init(walletProviderBaseURL: URL) {
        self.walletProviderBaseURL = walletProviderBaseURL
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 30
        self.session = URLSession(configuration: config)
    }

    // MARK: - WalletAttestationsProvider

    func getWalletAttestation(key: any JWK) async throws -> String {
        let url = walletProviderBaseURL
            .appendingPathComponent("wallet-instance-attestation")
            .appendingPathComponent("jwk")

        let body = buildJWKBody(from: key)
        let response: WalletInstanceAttestationResponse = try await post(url: url, body: body)
        return response.walletInstanceAttestation
    }

    func getKeysAttestation(keys: [any JWK], nonce: String?) async throws -> String {
        let url = walletProviderBaseURL
            .appendingPathComponent("wallet-unit-attestation")
            .appendingPathComponent("jwk-set")

        var body: [String: Any] = ["keys": keys.map { buildJWKDictionary(from: $0) }]
        if let nonce {
            body["nonce"] = nonce
        }
        let response: WalletUnitAttestationResponse = try await post(url: url, body: body)
        return response.walletUnitAttestation
    }

    // MARK: - Private helpers

    private func buildJWKBody(from key: any JWK) -> [String: Any] {
        return ["jwk": buildJWKDictionary(from: key)]
    }

    private func buildJWKDictionary(from key: any JWK) -> [String: Any] {
        return key.parameters as [String: Any]
    }

    private func post<T: Decodable>(url: URL, body: [String: Any]) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = [
            "Content-Type": "application/json",
            "Accept": "application/json"
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw WalletProviderError.unexpectedResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            throw WalletProviderError.http(statusCode: http.statusCode, body: data)
        }

        return try JSONDecoder().decode(T.self, from: data)
    }
}

// MARK: - Response models

private struct WalletInstanceAttestationResponse: Decodable {
    let walletInstanceAttestation: String
}

private struct WalletUnitAttestationResponse: Decodable {
    let walletUnitAttestation: String
}

// MARK: - Errors

enum WalletProviderError: LocalizedError {
    case unexpectedResponse
    case http(statusCode: Int, body: Data?)

    var errorDescription: String? {
        switch self {
        case .unexpectedResponse:
            return WalletStringKey.walletProviderUnexpectedResponse.localized()
        case .http(let code, _):
            return WalletStringKey.walletProviderHttpError.formattedLocalized(arguments: code)
        }
    }
}
