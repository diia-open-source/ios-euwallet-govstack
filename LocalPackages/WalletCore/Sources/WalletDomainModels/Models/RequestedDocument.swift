import Foundation

/// App-domain representation of a single document inside an `PresentationRequest`.
/// Replaces direct use of `EudiWalletKit.DocElements` in downstream code; collapses
/// the msoMdoc / sdJwt distinction into a flat set of fields keyed by namespace.
public struct RequestedDocument: Sendable, Hashable {
    /// Stable document id (same as upstream `docId`).
    public let id: String
    /// `docType` (mso-mdoc) or `vct` (sd-jwt) — whichever this document carries.
    public let docTypeOrVct: String
    public let isValid: Bool
    /// Requested fields grouped by namespace. Namespaces are upstream's MSO-MDoc
    /// concept; for SD-JWT documents the dictionary has a single key (the empty
    /// namespace or the doc's vct, depending on upstream's mapping).
    public let selectedItemsDictionary: [String: [RequestedField]]

    public init(
        id: String,
        docTypeOrVct: String,
        isValid: Bool,
        selectedItemsDictionary: [String: [RequestedField]]
    ) {
        self.id = id
        self.docTypeOrVct = docTypeOrVct
        self.isValid = isValid
        self.selectedItemsDictionary = selectedItemsDictionary
    }
}
