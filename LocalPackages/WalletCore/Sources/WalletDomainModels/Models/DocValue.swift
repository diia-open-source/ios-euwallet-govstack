//
//  DocValue.swift
//

import Foundation

public typealias DocValues = [String: [String: DocItemValue]]

public struct DocItemValue {
    public let namespace: String
    public let elementIdentifier: String
    public let docType: String
    public let documentDisplayName: String
    public let isOptional: Bool
    public let displayName: DocItemDisplayName
    public let valueName: String

    public init(namespace: String, elementIdentifier: String, docType: String, documentDisplayName: String, isOptional: Bool, displayName: DocItemDisplayName, valueName: String) {
        self.namespace = namespace
        self.elementIdentifier = elementIdentifier
        self.docType = docType
        self.documentDisplayName = documentDisplayName
        self.isOptional = isOptional
        self.displayName = displayName
        self.valueName = valueName
    }
}

public struct DocItemDisplayName {
    public let title: String
    public let subtitle: String?

    public init(title: String, subtitle: String?) {
        self.title = title
        self.subtitle = subtitle
    }
}
