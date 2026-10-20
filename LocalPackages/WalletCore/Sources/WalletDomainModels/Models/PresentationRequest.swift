//
//  PresentationRequest.swift
//

import Foundation

public struct PresentationRequest: Sendable {
    public let items: [RequestedDocument]
    public let relyingParty: String
    public let dataRequestInfo: String
    public let isTrusted: Bool

    public init(items: [RequestedDocument], relyingParty: String, dataRequestInfo: String, isTrusted: Bool) {
        self.items = items
        self.relyingParty = relyingParty
        self.dataRequestInfo = dataRequestInfo
        self.isTrusted = isTrusted
    }
}
