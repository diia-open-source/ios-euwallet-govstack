import Foundation
import WalletDocumentsCore

public protocol AddDocumentDocumentTypeMapperProtocol {
    func map(_ documentTypes: [AvailableDocumentType]) -> [AddDocumentItemViewData]
}

public struct AddDocumentDocumentTypeMapper: AddDocumentDocumentTypeMapperProtocol {
    public init() {}
    public func map(_ documentTypes: [AvailableDocumentType]) -> [AddDocumentItemViewData] {
        documentTypes.map {
            AddDocumentItemViewData(
                identifier: $0.identifier,
                issuerId: $0.issuerId,
                name: $0.name,
                description: $0.description
            )
        }
    }
}

public struct AddDocumentItemViewData {
    public let identifier: String
    public let issuerId: String
    public let name: String
    public let description: String

    public init(identifier: String, issuerId: String, name: String, description: String) {
        self.identifier = identifier
        self.issuerId = issuerId
        self.name = name
        self.description = description
    }

    /// Composite per-row key. The OID4VCI `credential_configuration_id` (`identifier`)
    /// is issuer-scoped — different issuers can publish the same id — so we combine it
    /// with `issuerId` to get a value that's unique across all rows in the picker.
    public var rowKey: String { "\(identifier)|\(issuerId)" }
}
