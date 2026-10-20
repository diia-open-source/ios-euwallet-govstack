//
//  PidDocumentModel.swift
//

import Foundation

public struct PidDocumentModel: Codable {
    public let id: String
    public let docType: String?
    public let createdAt: Date

    /// Credential-level display name as published by the issuer's OID4VCI metadata.
    /// Surfaced as the front-card title (see `PidDocumentViewStateFactory.documentDisplayName`).
    /// Nil when the issuer did not provide one or when restoring a model that
    /// predates this field; callers fall back to the local docType→string map.
    public let displayName: String?

    /// Cryptographic expiry from MSO `validityInfo.validUntil` (mDOC) or `exp`
    /// (SD-JWT) — full datetime (seconds). Drives `isExpired`; the `expiryDate`
    /// claim string below is still shown to the user as a date label. Nil for
    /// legacy models.
    public let validUntilDate: Date?

    // Agreed by the EU
    public let familyName: Field<String>?
    public let givenName: Field<String>?
    public let birthDate: Field<String>?
    public let birthPlace: Field<String>?
    public let birthCountry: Field<String>?
    public let birthState: Field<String>?
    public let birthCity: Field<String>?
    public let sex: Field<String>?
    public let nationality: Field<String>?
    public let ageOver18: Field<Bool>?
    public let ageInYears: Field<UInt64>?
    public let ageBirthYear: Field<UInt64>?
    public let expiryDate: Field<String>?
    public let issuingAuthority: Field<String>?
    public let issuanceDate: Field<String>?
    public let documentNumber: Field<String>?
    public let administrativeNumber: Field<String>?
    public let issuingCountry: Field<String>?
    public let issuingJurisdiction: Field<String>?
    public let emailAddress: Field<String>?
    public let mobilePhoneNumber: Field<String>?

    // Internal fields
    public let genderForDisplay: Field<String>?
    public let nationalityForDisplay: Field<String>?
    public let personalAdministrativeNumber: Field<String>?
    public let familyNameBirth: Field<String>?
    public let givenNameBirth: Field<String>?
    public let residentAddress: Field<String>?
    public let residentCity: Field<String>?
    public let residentPostalCode: Field<String>?
    public let residentState: Field<String>?
    public let residentCountry: Field<String>?
    public let residentStreet: Field<String>?
    public let residentHouseNumber: Field<String>?
    public let portrait: Field<String>?
    public let signature: Field<String>?

    // Unknown/additional fields not mapped to known properties
    public let unknownFields: [Field<String>]

    // MARK: - Codable Keys (for encoding/decoding only)

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case id
        case docType
        case createdAt
        case displayName = "display_name"
        case validUntilDate = "valid_until_date"
        case familyName = "family_name"
        case givenName = "given_name"
        case birthDate = "birth_date"
        case familyNameBirth = "family_name_birth"
        case givenNameBirth = "given_name_birth"
        case birthPlace = "birth_place"
        case birthCountry = "birth_country"
        case birthState = "birth_state"
        case birthCity = "birth_city"
        case residentAddress = "resident_address"
        case residentCity = "resident_city"
        case residentPostalCode = "resident_postal_code"
        case residentState = "resident_state"
        case residentCountry = "resident_country"
        case residentStreet = "resident_street"
        case residentHouseNumber = "resident_house_number"
        case sex
        case nationality
        case ageOver18 = "age_over_18"
        case ageInYears = "age_in_years"
        case ageBirthYear = "age_birth_year"
        case expiryDate = "expiry_date"
        case issuingAuthority = "issuing_authority"
        case issuanceDate = "issuance_date"
        case documentNumber = "document_number"
        case administrativeNumber = "administrative_number"
        case issuingCountry = "issuing_country"
        case issuingJurisdiction = "issuing_jurisdiction"
        case emailAddress = "email_address"
        case mobilePhoneNumber = "mobile_phone_number"
        case portrait
        case signature
        case unknownFields = "unknown_fields"

        case genderForDisplay = "gender_for_display"
        case nationalityForDisplay = "nationality_for_display"
        case personalAdministrativeNumber = "personal_administrative_number"
    }

    // MARK: - Claim Keys (for parsing document claims)

    /// Shared claim keys (EU PID Rulebook) — identical in both mDoc and SD-JWT formats
    private enum SharedClaimKeys {
        static let familyName = "family_name"
        static let givenName = "given_name"
        static let sex = "sex"
        static let sexUppercase = "SEX"
        static let gender = "gender"
        static let ageOver18 = "age_over_18"
        static let ageInYears = "age_in_years"
        static let ageBirthYear = "age_birth_year"
        static let issuingAuthority = "issuing_authority"
        static let documentNumber = "document_number"
        static let administrativeNumber = "administrative_number"
        static let issuingCountry = "issuing_country"
        static let issuingJurisdiction = "issuing_jurisdiction"
        static let personalAdministrativeNumber = "personal_administrative_number"
        static let signature = "signature"
        static let placeOfBirth = "place_of_birth"

        static let allKeys: Set<String> = [
            familyName, givenName, sex, sexUppercase, gender, ageOver18, ageInYears, ageBirthYear,
            issuingAuthority, documentNumber, administrativeNumber,
            issuingCountry, issuingJurisdiction, personalAdministrativeNumber,
            signature, placeOfBirth
        ]
    }

    /// Domestic claim keys — Ukrainian issuer-specific fields, not part of the EU PID Rulebook
    private enum DomesticClaimKeys {
        static let genderForDisplay = "gender_for_display"
        static let nationalityForDisplay = "nationality_for_display"

        static let allKeys: Set<String> = [
            genderForDisplay, nationalityForDisplay
        ]
    }

    /// mDoc (CBOR) format claim keys
    private enum MdocClaimKeys {
        static let birthDate = "birth_date"
        static let familyNameBirth = "family_name_birth"
        static let givenNameBirth = "given_name_birth"
        static let expiryDate = "expiry_date"
        static let issuanceDate = "issuance_date"
        static let emailAddress = "email_address"
        static let mobilePhoneNumber = "mobile_phone_number"
        static let nationality = "nationality"
        static let portrait = "portrait"
        static let birthPlace = "birth_place"
        static let birthCountry = "birth_country"
        static let birthState = "birth_state"
        static let birthCity = "birth_city"
        static let residentAddress = "resident_address"
        static let residentStreet = "resident_street"
        static let residentHouseNumber = "resident_house_number"
        static let residentCity = "resident_city"
        static let residentPostalCode = "resident_postal_code"
        static let residentState = "resident_state"
        static let residentCountry = "resident_country"

        static let allKeys: Set<String> = [
            birthDate, familyNameBirth, givenNameBirth, expiryDate, issuanceDate,
            emailAddress, mobilePhoneNumber, nationality, portrait,
            birthPlace, birthCountry, birthState, birthCity,
            residentAddress, residentStreet, residentHouseNumber,
            residentCity, residentPostalCode, residentState, residentCountry
        ]
    }

    /// SD-JWT format claim keys
    private enum SdJwtClaimKeys {
        static let birthDate = "birthdate"
        static let familyNameBirth = "birth_family_name"
        static let givenNameBirth = "birth_given_name"
        static let expiryDate = "date_of_expiry"
        static let issuanceDate = "date_of_issuance"
        static let emailAddress = "email"
        static let mobilePhoneNumber = "phone_number"
        static let nationality = "nationalities"
        static let portrait = "picture"
        static let photo = "photo"
        static let address = "address"

        // Nested address child keys
        static let streetAddress = "street_address"
        static let houseNumber = "house_number"
        static let locality = "locality"
        static let postalCode = "postal_code"
        static let region = "region"
        static let country = "country"
        static let formatted = "formatted"

        static let allKeys: Set<String> = [
            birthDate, familyNameBirth, givenNameBirth, expiryDate, issuanceDate,
            emailAddress, mobilePhoneNumber, nationality, portrait, photo, address
        ]
    }

    // MARK: - Init from DocClaimsDecodable

    public init(_ credential: Credential) {
        let docKeyValues = credential.claims.map { ($0.name, $0.dataValue) }
        // Resolve both maps identically so `makeField`'s children-check and value-read stay consistent on a duplicate name.
        let docFields = Dictionary(keepingFirst: docKeyValues)
        let docClaimsMap = Dictionary(keepingFirst: credential.claims.map { ($0.name, $0) })
        let format = credential.format

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

        // MARK: - Field factory helpers

        func makeField<T>(_ key: String) -> Field<T>? {
            // When a claim is structured (CBOR map/array — i.e. has children), its parent
            // stringValue is just a stringified blob like "{region: X,country: Y}" or "[X,Y]".
            // Refuse it here so a caller-specific children-aware path handles the claim
            // instead of leaking the blob into the UI.
            if let claim = docClaimsMap[key], let children = claim.children, !children.isEmpty {
                return nil
            }
            guard let value: T = docFields[key]?.getValue() else { return nil }
            // Empty parent strings also produce blank rows — treat empty-as-absent.
            if let stringValue = value as? String, stringValue.isEmpty { return nil }
            return Field(key: key, displayName: displayNames[key], value: value)
        }

        func makeFirstField<T>(_ keys: [String]) -> Field<T>? {
            for key in keys {
                if let field: Field<T> = makeField(key) {
                    return field
                }
            }
            return nil
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

        func makeChildField(_ key: String, from childrenMap: [String: String]) -> Field<String>? {
            guard let value = childrenMap[key], !value.isEmpty else { return nil }
            return Field(key: key, displayName: displayNames[key], value: value)
        }

        func makeFirstChildField(_ keys: [String], from childrenMap: [String: String]) -> Field<String>? {
            for key in keys {
                if let field = makeChildField(key, from: childrenMap) {
                    return field
                }
            }
            return nil
        }

        func childValuesMap(from claims: [DocumentClaim]) -> [String: String] {
            claims.reduce(into: [String: String]()) { result, claim in
                let value = claim.stringValue
                if !claim.name.isEmpty, !value.isEmpty {
                    result[claim.name] = value
                }
                if let children = claim.children, !children.isEmpty {
                    result.merge(childValuesMap(from: children)) { current, _ in current }
                }
            }
        }

        func makeImageField(_ keys: [String]) -> Field<String>? {
            for key in keys {
                // CBOR-bytes / decoded SD-JWT-bytes images arrive on `ClaimDataValue.imageData`,
                // which `getValue()` exposes as Data. Without this branch the parent stringValue
                // ("10369 bytes" descriptive label) is unparseable and the image is lost.
                if let imageData: Data = docFields[key]?.getValue() {
                    return Field(key: key, displayName: displayNames[key], value: imageData.base64EncodedString())
                }
                // SD-JWT VC carrying a base64-encoded image as a JSON string (incl. data: URI prefix).
                if let value: String = docFields[key]?.getValue(),
                   let imageValue = Self.normalizedImageString(value) {
                    return Field(key: key, displayName: displayNames[key], value: imageValue)
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

        // MARK: - Common fields (identical keys in both formats)
        familyName = makeField(SharedClaimKeys.familyName)
        givenName = makeField(SharedClaimKeys.givenName)
        sex = makeSexField([SharedClaimKeys.sex, SharedClaimKeys.sexUppercase])
        ageOver18 = makeField(SharedClaimKeys.ageOver18)
        ageInYears = makeField(SharedClaimKeys.ageInYears)
        ageBirthYear = makeField(SharedClaimKeys.ageBirthYear)
        issuingAuthority = makeField(SharedClaimKeys.issuingAuthority)
        documentNumber = makeField(SharedClaimKeys.documentNumber)
        administrativeNumber = makeField(SharedClaimKeys.administrativeNumber)
        issuingCountry = makeField(SharedClaimKeys.issuingCountry)
        issuingJurisdiction = makeField(SharedClaimKeys.issuingJurisdiction)
        personalAdministrativeNumber = makeField(SharedClaimKeys.personalAdministrativeNumber)

        // MARK: - Domestic fields (Ukrainian issuer-specific, not part of EU PID Rulebook)
        genderForDisplay = makeFirstField([DomesticClaimKeys.genderForDisplay, SharedClaimKeys.gender])
        nationalityForDisplay = makeField(DomesticClaimKeys.nationalityForDisplay)

        // MARK: - Format-specific fields (different keys per format)

        switch format {
        case .msoMdoc:
            birthDate = makeField(MdocClaimKeys.birthDate)
            familyNameBirth = makeField(MdocClaimKeys.familyNameBirth)
            givenNameBirth = makeField(MdocClaimKeys.givenNameBirth)
            expiryDate = makeField(MdocClaimKeys.expiryDate)
            issuanceDate = makeField(MdocClaimKeys.issuanceDate)
            emailAddress = makeField(MdocClaimKeys.emailAddress)
            mobilePhoneNumber = makeField(MdocClaimKeys.mobilePhoneNumber)
        case .sdJwtVc, .unknown:
            birthDate = makeFirstField([SdJwtClaimKeys.birthDate, MdocClaimKeys.birthDate])
            familyNameBirth = makeFirstField([SdJwtClaimKeys.familyNameBirth, MdocClaimKeys.familyNameBirth])
            givenNameBirth = makeFirstField([SdJwtClaimKeys.givenNameBirth, MdocClaimKeys.givenNameBirth])
            expiryDate = makeFirstField([SdJwtClaimKeys.expiryDate, MdocClaimKeys.expiryDate])
            issuanceDate = makeFirstField([SdJwtClaimKeys.issuanceDate, MdocClaimKeys.issuanceDate])
            emailAddress = makeFirstField([SdJwtClaimKeys.emailAddress, MdocClaimKeys.emailAddress])
            mobilePhoneNumber = makeFirstField([SdJwtClaimKeys.mobilePhoneNumber, MdocClaimKeys.mobilePhoneNumber])
        }

        // MARK: - Place of birth
        switch format {
        case .msoMdoc:
            // Pick a structured claim first — some mDoc issuers encode birth_place itself as a
            // CBOR map with locality/region/country children; others use the shared place_of_birth
            // key. In either case the parent stringValue is dict-formatted noise.
            let structuredBirthPlace = [MdocClaimKeys.birthPlace, SharedClaimKeys.placeOfBirth]
                .lazy
                .compactMap { docClaimsMap[$0] }
                .first(where: { ($0.children?.isEmpty == false) })

            if let claim = structuredBirthPlace, let children = claim.children {
                let childrenMap = childValuesMap(from: children)
                birthCity = makeChildField(SdJwtClaimKeys.locality, from: childrenMap)
                birthState = makeChildField(SdJwtClaimKeys.region, from: childrenMap)
                birthCountry = makeChildField(SdJwtClaimKeys.country, from: childrenMap)
                let placeComponents = [birthCity?.value, birthState?.value, birthCountry?.value]
                    .compactMap { $0 }
                    .filter { !$0.isEmpty }
                birthPlace = placeComponents.isEmpty ? nil : Field(
                    key: claim.name,
                    displayName: displayNames[claim.name],
                    value: placeComponents.joined(separator: ", ")
                )
            } else if let birthPlaceValue: String = docFields[MdocClaimKeys.birthPlace]?.getValue(), !birthPlaceValue.isEmpty {
                birthPlace = makeField(MdocClaimKeys.birthPlace)
                birthCountry = makeField(MdocClaimKeys.birthCountry)
                birthState = makeField(MdocClaimKeys.birthState)
                birthCity = makeField(MdocClaimKeys.birthCity)
            } else {
                birthPlace = nil
                birthCountry = makeField(MdocClaimKeys.birthCountry)
                birthState = makeField(MdocClaimKeys.birthState)
                birthCity = makeField(MdocClaimKeys.birthCity)
            }
        case .sdJwtVc, .unknown:
            // Structured place_of_birth (SD-JWT VC nested object) takes precedence over the
            // parent stringValue, which would otherwise be the dict-formatted blob.
            if let placeOfBirthClaim = docClaimsMap[SharedClaimKeys.placeOfBirth],
               let children = placeOfBirthClaim.children, !children.isEmpty {
                let childrenMap = childValuesMap(from: children)
                birthCity = makeFirstChildField([SdJwtClaimKeys.locality, MdocClaimKeys.birthCity], from: childrenMap)
                birthState = makeFirstChildField([SdJwtClaimKeys.region, MdocClaimKeys.birthState], from: childrenMap)
                birthCountry = makeFirstChildField([SdJwtClaimKeys.country, MdocClaimKeys.birthCountry], from: childrenMap)
                let placeComponents = [birthCity?.value, birthState?.value, birthCountry?.value]
                    .compactMap { $0 }
                    .filter { !$0.isEmpty }
                birthPlace = placeComponents.isEmpty ? nil : Field(
                    key: SharedClaimKeys.placeOfBirth,
                    displayName: displayNames[SharedClaimKeys.placeOfBirth],
                    value: placeComponents.joined(separator: ", ")
                )
            } else if let placeOfBirthValue: String = docFields[SharedClaimKeys.placeOfBirth]?.getValue(), !placeOfBirthValue.isEmpty {
                birthPlace = makeField(SharedClaimKeys.placeOfBirth)
                birthCountry = makeField(MdocClaimKeys.birthCountry)
                birthState = makeField(MdocClaimKeys.birthState)
                birthCity = makeField(MdocClaimKeys.birthCity)
            } else {
                birthPlace = nil
                birthCountry = nil
                birthState = nil
                birthCity = nil
            }
        }

        // MARK: - Address
        switch format {
        case .msoMdoc:
            residentAddress = makeField(MdocClaimKeys.residentAddress)
            residentStreet = makeField(MdocClaimKeys.residentStreet)
            residentHouseNumber = makeField(MdocClaimKeys.residentHouseNumber)
            residentCity = makeField(MdocClaimKeys.residentCity)
            residentPostalCode = makeField(MdocClaimKeys.residentPostalCode)
            residentState = makeField(MdocClaimKeys.residentState)
            residentCountry = makeField(MdocClaimKeys.residentCountry)
        case .sdJwtVc, .unknown:
            if let addressClaim = docClaimsMap[SdJwtClaimKeys.address],
               let children = addressClaim.children, !children.isEmpty {
                let addrMap = Dictionary(keepingFirst: children.map { ($0.name, $0.stringValue) })
                residentStreet = makeFirstChildField([SdJwtClaimKeys.streetAddress, MdocClaimKeys.residentStreet], from: addrMap)
                residentHouseNumber = makeFirstChildField([SdJwtClaimKeys.houseNumber, MdocClaimKeys.residentHouseNumber], from: addrMap)
                residentCity = makeFirstChildField([SdJwtClaimKeys.locality, MdocClaimKeys.residentCity], from: addrMap)
                residentPostalCode = makeFirstChildField([SdJwtClaimKeys.postalCode, MdocClaimKeys.residentPostalCode], from: addrMap)
                residentState = makeFirstChildField([SdJwtClaimKeys.region, MdocClaimKeys.residentState], from: addrMap)
                residentCountry = makeFirstChildField([SdJwtClaimKeys.country, MdocClaimKeys.residentCountry], from: addrMap)
                residentAddress = makeFirstChildField([SdJwtClaimKeys.formatted, MdocClaimKeys.residentAddress], from: addrMap)
            } else {
                residentAddress = nil
                residentStreet = nil
                residentHouseNumber = nil
                residentCity = nil
                residentPostalCode = nil
                residentState = nil
                residentCountry = nil
            }
        }

        // MARK: - Nationality
        let nationalityKeys: [String]
        switch format {
        case .msoMdoc: nationalityKeys = [MdocClaimKeys.nationality]
        case .sdJwtVc, .unknown: nationalityKeys = [SdJwtClaimKeys.nationality, MdocClaimKeys.nationality]
        }

        nationality = nationalityKeys.lazy.compactMap { key in
            // Check children first — when `nationality`/`nationalities` is encoded as a CBOR array
            // or SD-JWT array, the parent stringValue is a dict/array-formatted blob (e.g. "[1]"
            // or empty) and the real codes live in the children. Only fall back to the parent
            // string when there are no children (e.g. mDL, which encodes a simple "GR").
            if let nationalityClaim = docClaimsMap[key],
               let children = nationalityClaim.children, !children.isEmpty {
                let nationalityValues = children.map { $0.stringValue }.filter { !$0.isEmpty }
                let joined = nationalityValues.joined(separator: ", ")
                if !joined.isEmpty {
                    return Field(key: key, displayName: displayNames[key], value: joined)
                }
            }
            if let nationalityString: String = docFields[key]?.getValue(), !nationalityString.isEmpty {
                return Field(key: key, displayName: displayNames[key], value: nationalityString)
            }
            return nil
        }.first

        // MARK: - Portrait
        let portraitKeys: [String]
        switch format {
        case .msoMdoc: portraitKeys = [MdocClaimKeys.portrait]
        case .sdJwtVc, .unknown: portraitKeys = [SdJwtClaimKeys.portrait, MdocClaimKeys.portrait, SdJwtClaimKeys.photo]
        }

        portrait = makeImageField(portraitKeys)

        // MARK: - Signature
        signature = makeImageField([SharedClaimKeys.signature])

        // MARK: - Unknown fields
        var knownKeys = SharedClaimKeys.allKeys
        knownKeys.formUnion(DomesticClaimKeys.allKeys)

        switch format {
        case .msoMdoc:
            knownKeys.formUnion(MdocClaimKeys.allKeys)
        case .sdJwtVc, .unknown:
            knownKeys.formUnion(SdJwtClaimKeys.allKeys)
            knownKeys.formUnion(MdocClaimKeys.allKeys)
        }

        unknownFields = credential.claims
            .filter { !knownKeys.contains($0.name) }
            .compactMap { claim in
                let value = claim.stringValue
                guard !value.isEmpty else { return nil }
                return Field(key: claim.name, displayName: claim.displayName, value: value)
            }
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

    private static func normalizedImageString(_ value: String) -> String? {
        var imageValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if imageValue.hasPrefix("\""), imageValue.hasSuffix("\""), imageValue.count > 1 {
            imageValue = String(imageValue.dropFirst().dropLast())
        }
        if let commaIndex = imageValue.firstIndex(of: ","),
           imageValue[..<commaIndex].lowercased().contains("base64") {
            imageValue = String(imageValue[imageValue.index(after: commaIndex)...])
        }

        imageValue = imageValue
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")

        let paddingLength = (4 - imageValue.count % 4) % 4
        if paddingLength > 0 {
            imageValue += String(repeating: "=", count: paddingLength)
        }

        return Data(base64Encoded: imageValue, options: .ignoreUnknownCharacters) == nil ? nil : imageValue
    }
}
