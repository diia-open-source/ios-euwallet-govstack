//
//  WalletIssueCredentialsRequest.swift
//

import Foundation

public struct WalletIssueCredentialsRequest: Codable {
    public let doctype: String
    public let proofs: [WalletIssueCredentialsProof]

    public init(doctype: String, proofs: [WalletIssueCredentialsProof]) {
        self.doctype = doctype
        self.proofs = proofs
    }
}

public struct WalletIssueCredentialsProof: Codable {
    public let jwt: String
    public let proofType: String
    public let format: String

    public init(jwt: String, proofType: String, format: String) {
        self.jwt = jwt
        self.proofType = proofType
        self.format = format
    }
}
