import Foundation

/// App-domain representation of a single claim inside a `Credential`.
/// Replaces direct use of `MdocDataModel18013.DocClaim` in downstream code.
public struct DocumentClaim: Sendable, Hashable, Identifiable {
    public let id: String
    public let namespace: String?
    public let name: String
    public let displayName: String?
    public let path: [String]
    public let dataValue: ClaimDataValue
    public let isOptional: Bool
    public let order: Int
    public let children: [DocumentClaim]?

    public init(
        id: String,
        namespace: String? = nil,
        name: String,
        displayName: String? = nil,
        path: [String] = [],
        dataValue: ClaimDataValue,
        isOptional: Bool = false,
        order: Int = 0,
        children: [DocumentClaim]? = nil
    ) {
        self.id = id
        self.namespace = namespace
        self.name = name
        self.displayName = displayName
        self.path = path
        self.dataValue = dataValue
        self.isOptional = isOptional
        self.order = order
        self.children = children
    }

    /// Convenience accessor used widely by UI/mapper code.
    public var stringValue: String { dataValue.stringValue }
}
