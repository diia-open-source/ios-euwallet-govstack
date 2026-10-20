import Foundation

/// App-domain representation of a single field a verifier is asking for, or that the
/// wallet user has selected to disclose. Replaces direct use of
/// `MdocDataTransfer18013.RequestItem` in downstream code.
public struct RequestedField: Sendable, Hashable {
    /// Dotted path joined string — what UI typically displays as the "field name."
    public let elementIdentifier: String
    /// Full claim path (one element per level of nesting). The dotted join of this is
    /// `elementIdentifier`.
    public let elementPath: [String]
    /// `false` or `nil` upstream means the field is required.
    public let isOptional: Bool?
    public let intentToRetain: Bool?

    public init(
        elementIdentifier: String,
        elementPath: [String]? = nil,
        isOptional: Bool? = nil,
        intentToRetain: Bool? = nil
    ) {
        self.elementIdentifier = elementIdentifier
        self.elementPath = elementPath ?? elementIdentifier.components(separatedBy: ".")
        self.isOptional = isOptional
        self.intentToRetain = intentToRetain
    }
}
