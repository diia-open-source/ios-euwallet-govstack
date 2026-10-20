import Foundation

/// App-domain representation of a credential issuance offer.
///
/// Pure DTO — replaces direct use of `EudiWalletKit.OfferedIssuanceModel` in downstream code.
/// The SDK round-trip (resolve offer → issue documents against the resolved upstream) is handled inside `WalletKitController` via a private cache keyed by `uri`; if a cache miss happens (process restart mid-flow), the controller re-resolves transparently.
/// This struct intentionally carries no reference to any SDK type so it can move into `WalletDomainModels` in Phase F without dragging the SDK along.
public struct IssuanceOffer: Sendable {
    public let uri: String
    public let issuerName: String
    public let issuerLogoUrl: String?
    public let documents: [IssuanceOfferedDocument]
    public let txCodeSpec: TxCodeSpec?

    public var isTxCodeRequired: Bool { txCodeSpec != nil }

    public init(
        uri: String,
        issuerName: String,
        issuerLogoUrl: String?,
        documents: [IssuanceOfferedDocument],
        txCodeSpec: TxCodeSpec?
    ) {
        self.uri = uri
        self.issuerName = issuerName
        self.issuerLogoUrl = issuerLogoUrl
        self.documents = documents
        self.txCodeSpec = txCodeSpec
    }
}

public struct TxCodeSpec: Sendable {
    public let length: Int?
    public let isNumeric: Bool

    public init(length: Int?, isNumeric: Bool) {
        self.length = length
        self.isNumeric = isNumeric
    }
}

/// One document inside an `IssuanceOffer`.
public struct IssuanceOfferedDocument: Sendable {
    public let displayName: String
    public let docTypeOrVct: String?

    public init(displayName: String, docTypeOrVct: String?) {
        self.displayName = displayName
        self.docTypeOrVct = docTypeOrVct
    }
}
