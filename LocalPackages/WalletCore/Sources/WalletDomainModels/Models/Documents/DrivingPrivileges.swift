//
//  DrivingPrivileges.swift
//

import Foundation

/// Domain mirror of `MdocDataModel18013.DrivingPrivileges` — same Codable shape (matching property names and CodingKeys) so the existing `JSONDecoder().decode(DrivingPrivileges.self, from: ...)` path in `MdlDocumentModel.buildDrivingPrivileges(from:)` keeps working unchanged.
/// We do not need the SDK's CBOR conformances here — the MDL view-state factory reads `.drivingPrivileges.map(\.vehicleCategoryCode)` and the JSON round-trip already converts the CBOR claim tree.
/// Tracking the SDK shape: when the upstream model gains a field that wallet UI needs, mirror it here. This is a wallet domain type going forward, not a re-export.
public struct DrivingPrivileges: Codable, Sendable {
    public let drivingPrivileges: [DrivingPrivilege]

    public init(drivingPrivileges: [DrivingPrivilege]) {
        self.drivingPrivileges = drivingPrivileges
    }

    public subscript(i: Int) -> DrivingPrivilege { drivingPrivileges[i] }
}

public struct DrivingPrivilege: Codable, Sendable {
    public let vehicleCategoryCode: String
    public let issueDate: String?
    public let expiryDate: String?
    public let codes: [DrivingPrivilegeCode]?

    public init(
        vehicleCategoryCode: String,
        issueDate: String? = nil,
        expiryDate: String? = nil,
        codes: [DrivingPrivilegeCode]? = nil
    ) {
        self.vehicleCategoryCode = vehicleCategoryCode
        self.issueDate = issueDate
        self.expiryDate = expiryDate
        self.codes = codes
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case vehicleCategoryCode = "vehicle_category_code"
        case issueDate = "issue_date"
        case expiryDate = "expiry_date"
        case codes
    }
}

public struct DrivingPrivilegeCode: Codable, Sendable {
    public let code: String
    public let sign: String?
    public let value: String?

    public init(code: String, sign: String? = nil, value: String? = nil) {
        self.code = code
        self.sign = sign
        self.value = value
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case code
        case sign
        case value
    }
}
