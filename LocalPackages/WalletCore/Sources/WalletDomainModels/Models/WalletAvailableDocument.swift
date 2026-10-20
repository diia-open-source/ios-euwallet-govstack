//
//  WalletAvailableDocument.swift
//

import Foundation

/// Describes a document type the wallet can issue, as advertised by the issuer's OID4VCI metadata.
public struct WalletAvailableDocument: Sendable, Equatable {
    public let name: String
    public let issuerId: String
    public let identifier: String
    public let docType: String

    public init(
        name: String,
        issuerId: String,
        identifier: String,
        docType: String
    ) {
        self.name = name
        self.issuerId = issuerId
        self.identifier = identifier
        self.docType = docType
    }
}

