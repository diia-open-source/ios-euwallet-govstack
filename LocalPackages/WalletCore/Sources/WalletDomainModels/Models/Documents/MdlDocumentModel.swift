//
//  MdlDocumentModel.swift
//

import Foundation

public struct MdlDocumentModel: Codable {
    public let id: String
    public let docType: String?
    public let createdAt: Date

    /// Credential-level display name as published by the issuer's OID4VCI metadata.
    /// Surfaced as the front-card title (see `MdlDocumentViewStateFactory.documentDisplayName`).
    /// Nil when the issuer did not provide one or when restoring a model that
    /// predates this field; callers fall back to the local docType→string map.
    public let displayName: String?

    /// Cryptographic expiry from MSO `validityInfo.validUntil` — full datetime
    /// (seconds). Drives `isExpired`; the `expiryDate` claim string below is
    /// still shown to the user as a date label. Nil for legacy models.
    public let validUntilDate: Date?

    // Agreed by the EU
    public let familyName: Field<String>?
    public let givenName: Field<String>?
    public let birthDate: Field<String>?
    public let birthPlace: Field<String>?
    public let issueDate: Field<String>?
    public let expiryDate: Field<String>?
    public let issuingCountry: Field<String>?
    public let issuingAuthority: Field<String>?
    public let documentNumber: Field<String>?
    public let administrativeNumber: Field<String>?
    public var drivingPrivileges: DrivingPrivileges?
    public let nationality: Field<String>?
    public let eyeColour: Field<String>?
    public let hairColour: Field<String>?
    public let height: Field<UInt64>?
    public let weight: Field<UInt64>?
    public let sex: Field<String>?
    public let residentAddress: Field<String>?
    public let residentCountry: Field<String>?
    public let residentCity: Field<String>?
    public let residentState: Field<String>?
    public let residentPostalCode: Field<String>?
    public let ageOver18: Field<String>?
    public let ageInYears: Field<UInt64>?
    public var ageOverXX = [Int: Field<String>]()
    public let ageBirthYear: Field<UInt64>?
    public let portrait: Field<String>?
    public let unDistinguishingSign: Field<String>?
    public let issuingJurisdiction: Field<String>?
    public let portraitCaptureDate: Field<String>?
    public let familyNameNationalCharacter: Field<String>?
    public let givenNameNationalCharacter: Field<String>?
    public let signatureUsualMark: Field<String>?
    public let biometricTemplateFace: Field<String>?
    public let biometricTemplateSignatureSign: Field<String>?

    // MARK: - Internal fields
    public let issuingCountryForDisplayEng: Field<String>?
    public let nationalityForDisplay: Field<String>?
    public let genderForDisplay: Field<String>?

    // Unknown/additional fields not mapped to known properties
    public let unknownFields: [Field<String>]

    // MARK: - Claim Keys (ISO 18013-5 mDL standard)

    private enum ClaimKeys {
        static let familyName = "family_name"
        static let givenName = "given_name"
        static let birthDate = "birth_date"
        static let birthPlace = "birth_place"
        static let issueDate = "issue_date"
        static let expiryDate = "expiry_date"
        static let issuingCountry = "issuing_country"
        static let issuingAuthority = "issuing_authority"
        static let documentNumber = "document_number"
        static let administrativeNumber = "administrative_number"
        static let drivingPrivileges = "driving_privileges"
        static let unDistinguishingSign = "un_distinguishing_sign"
        static let nationality = "nationality"
        static let eyeColour = "eye_colour"
        static let hairColour = "hair_colour"
        static let height = "height"
        static let weight = "weight"
        static let sex = "sex"
        static let sexUppercase = "SEX"
        static let residentAddress = "resident_address"
        static let residentCity = "resident_city"
        static let residentState = "resident_state"
        static let residentPostalCode = "resident_postal_code"
        static let residentCountry = "resident_country"
        static let ageOver18 = "age_over_18"
        static let ageInYears = "age_in_years"
        static let ageBirthYear = "age_birth_year"
        static let portrait = "portrait"
        static let issuingJurisdiction = "issuing_jurisdiction"
        static let portraitCaptureDate = "portrait_capture_date"
        static let familyNameNationalCharacter = "family_name_national_character"
        static let givenNameNationalCharacter = "given_name_national_character"
        static let signatureUsualMark = "signature_usual_mark"
        static let biometricTemplateFace = "biometric_template_face"
        static let biometricTemplateSignatureSign = "biometric_template_signature_sign"

        static let allKeys: Set<String> = [
            familyName, givenName, birthDate, birthPlace, issueDate, expiryDate,
            issuingCountry, issuingAuthority, documentNumber, administrativeNumber,
            drivingPrivileges, unDistinguishingSign, nationality, eyeColour, hairColour,
            height, weight, sex, sexUppercase, residentAddress, residentCity, residentState,
            residentPostalCode, residentCountry, ageOver18, ageInYears, ageBirthYear,
            portrait, issuingJurisdiction, portraitCaptureDate,
            familyNameNationalCharacter, givenNameNationalCharacter,
            signatureUsualMark, biometricTemplateFace, biometricTemplateSignatureSign
        ]
    }

    /// Domestic claim keys — Ukrainian issuer-specific fields, not part of ISO 18013-5
    private enum DomesticClaimKeys {
        static let issuingCountryForDisplayEng = "issuing_country_for_display_eng"
        static let genderForDisplay = "gender_for_display"
        static let nationalityForDisplay = "nationality_for_display"

        static let allKeys: Set<String> = [
            issuingCountryForDisplayEng, genderForDisplay, nationalityForDisplay
        ]
    }

    // MARK: - CodingKeys (for encoding/decoding only)

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case id
        case docType
        case createdAt
        case displayName = "display_name"
        case validUntilDate = "valid_until_date"
        case familyName = "family_name"
        case givenName = "given_name"
        case birthDate = "birth_date"
        case birthPlace = "birth_place"
        case issueDate = "issue_date"
        case expiryDate = "expiry_date"
        case issuingCountry = "issuing_country"
        case issuingAuthority = "issuing_authority"
        case documentNumber = "document_number"
        case administrativeNumber = "administrative_number"
        case drivingPrivileges = "driving_privileges"
        case unDistinguishingSign = "un_distinguishing_sign"
        case nationality = "nationality"
        case eyeColour = "eye_colour"
        case hairColour = "hair_colour"
        case height = "height"
        case weight = "weight"
        case sex = "sex"
        case residentAddress = "resident_address"
        case residentCity = "resident_city"
        case residentState = "resident_state"
        case residentPostalCode = "resident_postal_code"
        case residentCountry = "resident_country"
        case ageOver18 = "age_over_18"
        case ageInYears = "age_in_years"
        case ageBirthYear = "age_birth_year"
        case portrait = "portrait"
        case issuingJurisdiction = "issuing_jurisdiction"
        case portraitCaptureDate = "portrait_capture_date"
        case familyNameNationalCharacter = "family_name_national_character"
        case givenNameNationalCharacter = "given_name_national_character"
        case signatureUsualMark = "signature_usual_mark"
        case biometricTemplateFace = "biometric_template_face"
        case biometricTemplateSignatureSign = "biometric_template_signature_sign"
        case unknownFields = "unknown_fields"

        case issuingCountryForDisplayEng = "issuing_country_for_display_eng"
        case genderForDisplay = "gender_for_display"
        case nationalityForDisplay = "nationality_for_display"
    }

    // MARK: - Init from DocClaimsDecodable

    public init(_ credential: Credential) {
        let docKeyValues = credential.claims.map { ($0.name, $0.dataValue) }
        // Resolve both maps identically so `makeField`'s children-check and value-read stay consistent on a duplicate name.
        let docFields = Dictionary(keepingFirst: docKeyValues)
        let docClaimsMap = Dictionary(keepingFirst: credential.claims.map { ($0.name, $0) })

        // MARK: - Build display names from issuer metadata
        var displayNames: [String: String] = [:]
        for claim in credential.claims {
            if let displayName = claim.displayName, !displayName.isEmpty {
                displayNames[claim.name] = displayName
            }
            if let children = claim.children {
                for child in children {
                    if let childDisplayName = child.displayName, !childDisplayName.isEmpty {
                        displayNames[child.name] = childDisplayName
                    }
                }
            }
        }

        // MARK: - Field factory helper

        func makeField<T>(_ key: String) -> Field<T>? {
            // Refuse the parent stringValue when the claim is structured (has children) —
            // the parent value of a CBOR map/array is a dict-formatted blob, not a single value.
            if let claim = docClaimsMap[key], let children = claim.children, !children.isEmpty {
                return nil
            }
            guard let value: T = docFields[key]?.getValue() else { return nil }
            if let stringValue = value as? String, stringValue.isEmpty { return nil }
            return Field(key: key, displayName: displayNames[key], value: value)
        }

        func makeStringField(_ key: String) -> Field<String>? {
            guard let claim = docClaimsMap[key],
                  let value = Self.claimStringValue(from: claim) else { return nil }
            return Field(key: key, displayName: displayNames[key], value: value)
        }

        func makeUInt64Field(_ key: String) -> Field<UInt64>? {
            if let value: UInt64 = docFields[key]?.getValue() {
                return Field(key: key, displayName: displayNames[key], value: value)
            }

            guard let stringValue: String = docFields[key]?.getValue(),
                  let value = UInt64(stringValue.trimmingCharacters(in: .whitespacesAndNewlines))
            else { return nil }
            return Field(key: key, displayName: displayNames[key], value: value)
        }

        func makeSexField(_ keys: [String]) -> Field<String>? {
            for key in keys {
                if let claim = docClaimsMap[key],
                   let value = Self.sexValue(from: claim) {
                    return Field(key: key, displayName: displayNames[key], value: value)
                }
            }

            for key in keys {
                if let claim = credential.claims.first(where: { $0.name.caseInsensitiveCompare(key) == .orderedSame }),
                   let value = Self.sexValue(from: claim) {
                    return Field(key: claim.name, displayName: claim.displayName ?? displayNames[claim.name], value: value)
                }
            }

            return nil
        }

        // MARK: - Metadata
        id = credential.id
        docType = credential.docType
        createdAt = Date()
        displayName = credential.displayName
        validUntilDate = credential.validUntil

        // MARK: - Standard fields
        familyName = makeField(ClaimKeys.familyName)
        givenName = makeField(ClaimKeys.givenName)
        birthDate = makeField(ClaimKeys.birthDate)
        birthPlace = makeField(ClaimKeys.birthPlace)
        issueDate = makeField(ClaimKeys.issueDate)
        expiryDate = makeField(ClaimKeys.expiryDate)
        issuingCountry = makeField(ClaimKeys.issuingCountry)
        issuingAuthority = makeField(ClaimKeys.issuingAuthority)
        documentNumber = makeField(ClaimKeys.documentNumber)
        administrativeNumber = makeField(ClaimKeys.administrativeNumber)
        eyeColour = makeField(ClaimKeys.eyeColour)
        hairColour = makeField(ClaimKeys.hairColour)
        height = makeUInt64Field(ClaimKeys.height)
        weight = makeUInt64Field(ClaimKeys.weight)
        sex = makeSexField([ClaimKeys.sex, ClaimKeys.sexUppercase])
        residentAddress = makeField(ClaimKeys.residentAddress)
        residentCountry = makeField(ClaimKeys.residentCountry)
        residentCity = makeField(ClaimKeys.residentCity)
        residentState = makeField(ClaimKeys.residentState)
        residentPostalCode = makeField(ClaimKeys.residentPostalCode)
        ageOver18 = makeStringField(ClaimKeys.ageOver18)
        ageInYears = makeField(ClaimKeys.ageInYears)
        ageBirthYear = makeField(ClaimKeys.ageBirthYear)
        ageOverXX = credential.claims.reduce(into: [Int: Field<String>]()) { result, claim in
            guard let threshold = Self.ageOverThreshold(from: claim.name),
                  threshold != 18,
                  let value = Self.claimStringValue(from: claim) else { return }
            result[threshold] = Field(key: claim.name, displayName: claim.displayName ?? displayNames[claim.name], value: value)
        }
        unDistinguishingSign = makeField(ClaimKeys.unDistinguishingSign)
        issuingJurisdiction = makeField(ClaimKeys.issuingJurisdiction)
        portraitCaptureDate = makeField(ClaimKeys.portraitCaptureDate)
        familyNameNationalCharacter = makeField(ClaimKeys.familyNameNationalCharacter)
        givenNameNationalCharacter = makeField(ClaimKeys.givenNameNationalCharacter)
        biometricTemplateFace = makeField(ClaimKeys.biometricTemplateFace)
        biometricTemplateSignatureSign = makeField(ClaimKeys.biometricTemplateSignatureSign)

        // MARK: - Domestic fields (Ukrainian issuer-specific, not part of ISO 18013-5)
        issuingCountryForDisplayEng = makeField(DomesticClaimKeys.issuingCountryForDisplayEng)
        genderForDisplay = makeField(DomesticClaimKeys.genderForDisplay)
        nationalityForDisplay = makeField(DomesticClaimKeys.nationalityForDisplay)

        // MARK: - Nationality (can be array with children or string)
        // Children-first: a structured nationality claim has a dict/array-formatted parent
        // stringValue; the real codes live in the children. Only fall back to the parent
        // string when no children exist (e.g. mDL simple "GR").
        nationality = {
            if let nationalityClaim = docClaimsMap[ClaimKeys.nationality],
               let children = nationalityClaim.children, !children.isEmpty {
                let values = children.map { $0.stringValue }.filter { !$0.isEmpty }
                let joined = values.joined(separator: ", ")
                if !joined.isEmpty {
                    return Field(key: ClaimKeys.nationality, displayName: displayNames[ClaimKeys.nationality], value: joined)
                }
            }
            if let nationalityString: String = docFields[ClaimKeys.nationality]?.getValue(), !nationalityString.isEmpty {
                return Field(key: ClaimKeys.nationality, displayName: displayNames[ClaimKeys.nationality], value: nationalityString)
            }
            return nil
        }()

        // MARK: - Portrait (bytes → base64)
        // CBOR-bytes images arrive on `ClaimDataValue.imageData`, which `getValue()` exposes
        // as `Data`. The legacy `[UInt8]` shape is never returned, so it must come first.
        if let portraitData: Data = docFields[ClaimKeys.portrait]?.getValue() {
            portrait = Field(key: ClaimKeys.portrait, displayName: displayNames[ClaimKeys.portrait], value: portraitData.base64EncodedString())
        } else {
            portrait = nil
        }

        // MARK: - Signature (bytes → base64)
        if let signatureData: Data = docFields[ClaimKeys.signatureUsualMark]?.getValue() {
            signatureUsualMark = Field(key: ClaimKeys.signatureUsualMark, displayName: displayNames[ClaimKeys.signatureUsualMark], value: signatureData.base64EncodedString())
        } else {
            signatureUsualMark = nil
        }

        // MARK: - Driving privileges
        // Before Step 4 of the wrap, this was extracted via downcast to the upstream
        // `IsoMdlModel`. Credential no longer carries the upstream concrete type, so we
        // reconstruct `DrivingPrivileges` from the generic claim tree: the parent claim
        // `driving_privileges` has one child per privilege, each of which has
        // grandchildren `vehicle_category_code` / `issue_date` / `expiry_date` / `codes`.
        drivingPrivileges = Self.buildDrivingPrivileges(from: credential.claims)

        // MARK: - Unknown fields
        let allKnownKeys = ClaimKeys.allKeys.union(DomesticClaimKeys.allKeys)
        unknownFields = credential.claims
            .filter { !allKnownKeys.contains($0.name) && Self.ageOverThreshold(from: $0.name) == nil }
            .compactMap { claim in
                let value = claim.stringValue
                guard !value.isEmpty else { return nil }
                return Field(key: claim.name, displayName: claim.displayName, value: value)
            }
    }

    // MARK: - Driving privileges helper

    /// Walk the `driving_privileges` claim subtree and JSON-round-trip into the upstream
    /// `DrivingPrivileges` struct so callers can keep using `drivingPrivileges.drivingPrivileges.map(\.vehicleCategoryCode)`.
    private static func buildDrivingPrivileges(from claims: [DocumentClaim]) -> DrivingPrivileges? {
        guard let parent = claims.first(where: { $0.name == ClaimKeys.drivingPrivileges }),
              let children = parent.children, !children.isEmpty else {
            return nil
        }

        let privilegeDicts: [[String: Any]] = children.compactMap { child in
            guard let grandchildren = child.children else { return nil }
            var dict: [String: Any] = [:]
            for gc in grandchildren {
                let trimmed = gc.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { continue }
                dict[gc.name] = trimmed
            }
            return dict.isEmpty ? nil : dict
        }

        guard !privilegeDicts.isEmpty else { return nil }

        let payload: [String: Any] = ["drivingPrivileges": privilegeDicts]
        guard let data = try? JSONSerialization.data(withJSONObject: payload),
              let result = try? JSONDecoder().decode(DrivingPrivileges.self, from: data) else {
            return nil
        }
        return result
    }

    // MARK: - Claim Parsing Helpers

    private static func sexValue(from claim: DocumentClaim) -> String? {
        if let value: UInt64 = claim.dataValue.getValue() {
            return normalizedSexCode("\(value)") ?? normalizedSexRawValue(claim.stringValue)
        }
        if let value: Int = claim.dataValue.getValue() {
            return normalizedSexCode("\(value)") ?? normalizedSexRawValue(claim.stringValue)
        }
        if let value: Int64 = claim.dataValue.getValue() {
            return normalizedSexCode("\(value)") ?? normalizedSexRawValue(claim.stringValue)
        }
        if let value: String = claim.dataValue.getValue() {
            return normalizedSexCode(value) ?? normalizedSexRawValue(claim.stringValue)
        }

        return normalizedSexRawValue(claim.stringValue)
    }

    private static func normalizedSexCode(_ value: String) -> String? {
        let normalizedValue = value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "\""))

        switch normalizedValue {
        case "0", "1", "2", "9":
            return normalizedValue
        default:
            return nil
        }
    }

    private static func normalizedSexRawValue(_ value: String) -> String? {
        let normalizedValue = value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "\""))

        return normalizedValue.isEmpty ? nil : normalizedValue
    }

    private static func ageOverThreshold(from key: String) -> Int? {
        let prefix = "age_over_"
        guard key.hasPrefix(prefix) else { return nil }
        return Int(key.dropFirst(prefix.count))
    }

    private static func claimStringValue(from claim: DocumentClaim) -> String? {
        if let value: Bool = claim.dataValue.getValue() {
            return "\(value)"
        }
        if let value: UInt64 = claim.dataValue.getValue() {
            return "\(value)"
        }
        if let value: Int = claim.dataValue.getValue() {
            return "\(value)"
        }
        if let value: Int64 = claim.dataValue.getValue() {
            return "\(value)"
        }
        if let value: String = claim.dataValue.getValue() {
            return value
        }

        let value = claim.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }
}
