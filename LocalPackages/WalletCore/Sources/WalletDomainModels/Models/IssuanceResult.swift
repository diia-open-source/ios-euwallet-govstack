import Foundation

/// App-domain representation of a single document produced by an issuance call.
///
/// Replaces direct use of `WalletStorage.Document` (and `EudiWalletKit`'s
/// `authorizePresentationUrl` extension) in downstream issuance code.
public struct IssuanceResult: Sendable, Hashable {
    public let id: String
    public let docType: String
    public let authorizePresentationUrl: String?
    public let status: Status

    public init(
        id: String,
        docType: String,
        authorizePresentationUrl: String?,
        status: Status
    ) {
        self.id = id
        self.docType = docType
        self.authorizePresentationUrl = authorizePresentationUrl
        self.status = status
    }

    public enum Status: String, Sendable, CaseIterable, Hashable {
        case issued
        case deferred
        case pending
    }

    public var isDeferred: Bool { status == .deferred }
    public var isPending: Bool { status == .pending }
}
