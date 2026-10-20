//
//  MdlDocumentViewStateFactory.swift
//

import Foundation
import DiiaCommonTypes
import DiiaUIComponents
import WalletDocumentsCommonTypes
import WalletCore
import WalletDomainModels

public protocol MdlDocumentViewStateFactoryProtocol {
    func make(document: MdlDocumentModel) -> DSFullDocumentModel
}

public struct MdlDocumentViewStateFactory: MdlDocumentViewStateFactoryProtocol {
    public init() {}
    public func make(document: MdlDocumentModel) -> DSFullDocumentModel {
        let frontCard = frontCardModel(document: document)
        let fullInfoComponents = fullInfo(document: document)

        return DSFullDocumentModel(
            status: .ok,
            expirationDate: expirationDate(document: document),
            data: [
                DSDocumentData(
                    docStatus: 200,
                    id: document.id,
                    docNumber: document.documentNumber?.value ?? .empty,
                    content: [
                        document.portrait.map { DSDocumentContent(image: $0.value, code: .photo) },
                        document.signatureUsualMark.map { DSDocumentContent(image: $0.value, code: .signature) }
                    ].compactMap { $0 },
                    docData: DSDocData(
                        docName: WalletStringKey.mdlDocumentName.localized(),
                        docType: document.docType,
                        fullName: fullNameValue(document: document)
                    ),
                    frontCard: frontCard,
                    fullInfo: fullInfoComponents
                )
            ]
        )
    }

    // MARK: - Front Card
    private func frontCardModel(document: MdlDocumentModel) -> DSDocumentModel {
        DSDocumentModel(
            docHeadingOrg: DSDocumentHeading(
                headingWithSubtitlesMlc: DSHeadingWithSubtitlesModel(
                    value: documentDisplayName(document: document),
                    subtitles: nil
                )
            ),
            tableBlockTwoColumnsPlaneOrg: DSTableBlockTwoColumnPlaneOrg(
                photo: .photo,
                items: [
                    formattedDocumentTextDate(for: document.birthDate?.value).map { value in
                        DSItemsModel(tableItemVerticalMlc: DSTableItemVerticalMlc(
                            label: "\(title(for: document.birthDate, fallback: WalletStringKey.eudiLabelDateOfBirth.localized())):",
                            value: value)
                        )
                    },
                    categories(document: document).map {
                        DSItemsModel(tableItemVerticalMlc: DSTableItemVerticalMlc(
                            label: "\(WalletStringKey.eudiLabelCategory.localized()):",
                            value: $0)
                        )
                    },
                    document.signatureUsualMark.map { _ in
                        DSItemsModel(tableItemVerticalMlc: DSTableItemVerticalMlc(
                            valueImage: .signature)
                        )
                    }
                ].compactMap { $0 },
                headingWithSubtitlesMlc: nil
            ),
            tickerAtm: DSTickerAtom(
                usage: .document,
                type: .blue,
                value: documentValidUntilTickerValue(document: document)
            ),
            // Cardholder name in the prominent bottom heading — Given + Family
            // (Latin) only. The national-character form is intentionally not shown
            // on the front card; it appears only in the full-info section.
            docButtonHeadingOrg: DSDocumentHeading(
                headingWithSubtitlesMlc: DSHeadingWithSubtitlesModel(
                    value: name(document: document),
                    subtitles: nil
                ),
                iconAtm: DSIconModel(
                    code: "ellipseKebab",
                    action: DSActionParameter(type: "ellipseMenu", subtype: "mdl")
                )
            )
        )
    }

    // MARK: - Full Info
    private func fullInfo(document: MdlDocumentModel) -> [AnyCodable] {
        let docNumberCopy: DSTableItemPrimaryMlc? = document.documentNumber.map {
            DSTableItemPrimaryMlc(label: nil, value: $0.value, icon: nil)
        }

        let heading = DSDocumentHeading(
            headingWithSubtitlesMlc: DSHeadingWithSubtitlesModel(
                value: documentDisplayName(document: document),
                subtitles: nil
            ),
            docNumberCopyMlc: docNumberCopy
        )

        return [
            .component(.docHeadingOrg, heading),

            .component(.tickerAtm, DSTickerAtom(
                usage: .document,
                type: .blue,
                value: documentValidUntilTickerValue(document: document)
            )),

            .component(.tableBlockTwoColumnsOrg, DSTableBlockTwoColumnPlaneOrg(
                photo: .photo,
                items: [
                    formattedDocumentTextDate(for: document.birthDate?.value).map { value in
                        DSItemsModel(tableItemVerticalMlc: DSTableItemVerticalMlc(
                            label: "\(title(for: document.birthDate, fallback: WalletStringKey.eudiLabelDateOfBirth.localized())):",
                            value: value)
                        )
                    },
                    categories(document: document).map {
                        DSItemsModel(tableItemVerticalMlc: DSTableItemVerticalMlc(
                            label: "\(WalletStringKey.eudiLabelCategory.localized()):",
                            value: $0)
                        )
                    },
                    document.signatureUsualMark.map { _ in
                        DSItemsModel(tableItemVerticalMlc: DSTableItemVerticalMlc(
                            valueImage: .signature)
                        )
                    }
                ].compactMap { $0 },
                headingWithSubtitlesMlc: DSHeadingWithSubtitlesModel(
                    value: name(document: document),
                    subtitles: fullname(document: document).isEmpty ? nil : [fullname(document: document)]
                )
            )),

            // Per-privilege detail rows: category, issue date, expiry date.
            // The front-card `categories()` only joins the letters.
            (document.drivingPrivileges?.drivingPrivileges.isEmpty == false) ? .component(.tableBlockOrg, DSTableBlockItemModel(
                tableMainHeadingMlc: nil,
                tableSecondaryHeadingMlc: nil,
                items: drivingPrivilegeDetailItems(document: document)
            )) : nil,

            hasPersonalInfoData(document: document) ? .component(.tableBlockOrg, DSTableBlockItemModel(
                tableMainHeadingMlc: nil,
                tableSecondaryHeadingMlc: nil,
                items: [
                    (document.nationalityForDisplay ?? document.nationality).map {
                        makeFieldItem(
                            label: title(for: $0, fallback: WalletStringKey.eudiLabelNationality.localized()),
                            value: $0.value
                        )
                    },
                    sexDisplay(document: document).map {
                        makeFieldItem(
                            label: sexTitle(document: document),
                            value: $0
                        )
                    },
                    document.birthPlace.map {
                        makeFieldItem(
                            label: title(for: $0, fallback: WalletStringKey.eudiLabelPlaceOfBirth.localized()),
                            value: $0.value
                        )
                    }
                ].compactMap { $0 }
            )) : nil,

            hasIssueData(document: document) ? .component(.tableBlockOrg, DSTableBlockItemModel(
                tableMainHeadingMlc: nil,
                tableSecondaryHeadingMlc: nil,
                items: [
                    document.administrativeNumber.map {
                        makeVerticalFieldItem(
                            label: title(for: $0, fallback: WalletStringKey.eudiLabelAdministrativeNumber.localized()),
                            value: $0.value
                        )
                    },
                    formattedDocumentNumericDate(for: document.issueDate?.value).map { value in
                        makeVerticalFieldItem(
                            label: title(for: document.issueDate, fallback: WalletStringKey.eudiLabelDateOfIssue.localized()),
                            value: value
                        )
                    },
                    formattedDocumentNumericDate(for: document.expiryDate?.value).map { value in
                        makeVerticalFieldItem(
                            label: title(for: document.expiryDate, fallback: WalletStringKey.eudiLabelExpiryDate.localized()),
                            value: value
                        )
                    },
                    document.issuingAuthority.map {
                        makeVerticalFieldItem(
                            label: title(for: $0, fallback: WalletStringKey.eudiLabelAuthority.localized()),
                            value: $0.value
                        )
                    },
                    (document.issuingCountryForDisplayEng ?? document.issuingCountry).map {
                        makeVerticalFieldItem(
                            label: title(for: $0, fallback: WalletStringKey.eudiLabelIssuingCountry.localized()),
                            value: $0.value
                        )
                    }
                ].compactMap { $0 }
            )) : nil,

            // Resident address — single combined block.
            // The ISO 18013-5 resident_* elements are distinct data elements; we
            // join the populated ones into one row for display.
            residenceAddressValue(document: document).map { value in
                AnyCodable.component(.tableBlockOrg, DSTableBlockItemModel(
                    tableMainHeadingMlc: nil,
                    tableSecondaryHeadingMlc: nil,
                    items: [
                        makeVerticalFieldItem(
                            label: WalletStringKey.eudiLabelResidentAddress.localized(),
                            value: value
                        )
                    ]
                ))
            },

            hasPhysicalCharacteristics(document: document) ? .component(.tableBlockOrg, DSTableBlockItemModel(
                tableMainHeadingMlc: nil,
                tableSecondaryHeadingMlc: nil,
                items: [
                    document.height.map {
                        makeFieldItem(
                            label: title(for: $0, fallback: WalletStringKey.eudiLabelHeight.localized()),
                            value: "\($0.value) cm"
                        )
                    },
                    document.weight.map {
                        makeFieldItem(
                            label: title(for: $0, fallback: WalletStringKey.eudiLabelWeight.localized()),
                            value: "\($0.value) kg"
                        )
                    },
                    document.eyeColour.map {
                        makeFieldItem(
                            label: title(for: $0, fallback: WalletStringKey.eudiLabelEyeColour.localized()),
                            value: $0.value
                        )
                    },
                    document.hairColour.map {
                        makeFieldItem(
                            label: title(for: $0, fallback: WalletStringKey.eudiLabelHairColour.localized()),
                            value: $0.value
                        )
                    }
                ].compactMap { $0 }
            )) : nil,

            unknownFieldsSection(document: document)
        ].compactMap { $0 }
    }

    /// JWT / SD-JWT envelope + issuer-metadata claims that occasionally leak
    /// into `unknownFields` but are not user-facing data. Mirrors the same set
    /// in PidDocumentViewStateFactory.
    private static let suppressedUnknownFieldKeys: Set<String> = [
        "trust_anchor",
        "iat", "exp", "nbf", "sub", "iss",
        "vct", "_sd_alg", "cnf"
    ]

    private func unknownFieldsSection(document: MdlDocumentModel) -> AnyCodable? {
        let filtered = document.unknownFields.filter {
            !Self.suppressedUnknownFieldKeys.contains($0.key)
        }
        guard !filtered.isEmpty else { return nil }
        return .component(.tableBlockOrg, DSTableBlockItemModel(
            tableMainHeadingMlc: nil,
            tableSecondaryHeadingMlc: nil,
            items: filtered.map {
                makeFieldItem(label: $0.displayName, value: $0.value)
            }
        ))
    }

    // MARK: - Section Visibility Helpers

    private func hasPersonalInfoData(document: MdlDocumentModel) -> Bool {
        document.nationalityForDisplay != nil
            || document.nationality != nil
            || document.genderForDisplay != nil
            || document.sex != nil
            || document.birthPlace != nil
    }

    private func hasIssueData(document: MdlDocumentModel) -> Bool {
        document.administrativeNumber != nil
            || document.issueDate != nil
            || document.expiryDate != nil
            || document.issuingAuthority != nil
            || document.issuingCountryForDisplayEng != nil
            || document.issuingCountry != nil
    }

    private func hasPhysicalCharacteristics(document: MdlDocumentModel) -> Bool {
        document.height != nil
            || document.weight != nil
            || document.eyeColour != nil
            || document.hairColour != nil
    }

    /// Joins the populated ISO 18013-5 `resident_*` data elements into a single
    /// display string in the order country → state → city → address → postal code.
    /// Returns nil when no component is present, so the whole block is dropped.
    private func residenceAddressValue(document: MdlDocumentModel) -> String? {
        let parts = [
            document.residentCountry?.value,
            document.residentState?.value,
            document.residentCity?.value,
            document.residentAddress?.value,
            document.residentPostalCode?.value
        ]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
        return parts.isEmpty ? nil : parts.joined(separator: ", ")
    }

    // MARK: - Domain Helpers

    /// Display name shown on the front card. Priority:
    /// 1. The issuer's OID4VCI credential-level `display.name` (`credential.displayName`),
    ///    so what the user sees matches what the issuer intended to publish.
    /// 2. Fallback — the local docType→string map (e.g. "mDL (mDoc)") used when the
    ///    issuer published no display name.
    /// 3. Fallback — the generic mDL localized string for unknown docTypes.
    private func documentDisplayName(document: MdlDocumentModel) -> String {
        if let issuerName = document.displayName, !issuerName.isEmpty {
            return issuerName
        }
        guard let docType = document.docType,
              let walletDocType = WalletDocumentType(rawValue: docType) else {
            return WalletStringKey.mdlDocumentName.localized()
        }
        return walletDocType.displayName
    }

    private func makeFieldItem(label: String, value: String) -> DSTableItem {
        DSTableItem(tableItemHorizontalMlc: DSTableItemHorizontalMlc(
            label: "\(label):",
            value: value)
        )
    }

    private func makeVerticalFieldItem(label: String, value: String) -> DSTableItem {
        DSTableItem(tableItemVerticalMlc: DSTableItemVerticalMlc(
            label: "\(label):",
            value: value)
        )
    }

    private func title<T: Codable & Hashable>(for field: Field<T>?, fallback: String) -> String {
        guard let displayName = field?.displayName, !displayName.isEmpty else {
            return fallback
        }

        switch field?.key {
        case "birth_date":
            return WalletStringKey.eudiLabelDateOfBirth.localized()
        case "family_name":
            return WalletStringKey.eudiLabelFamilyName.localized()
        case "given_name":
            return WalletStringKey.eudiLabelGivenName.localized()
        case "nationality", "nationality_for_display":
            return WalletStringKey.eudiLabelNationality.localized()
        case "sex", "gender_for_display":
            return WalletStringKey.eudiLabelSex.localized()
        case "age_over_18":
            return WalletStringKey.eudiLabelAgeOver18.localized()
        case "age_in_years":
            return WalletStringKey.eudiLabelAge.localized()
        case "age_birth_year":
            return WalletStringKey.eudiLabelAgeBirthYear.localized()
        case "birth_place":
            return WalletStringKey.eudiLabelPlaceOfBirth.localized()
        case "administrative_number":
            return WalletStringKey.eudiLabelAdministrativeNumber.localized()
        case "issue_date":
            return WalletStringKey.eudiLabelDateOfIssue.localized()
        case "expiry_date":
            return WalletStringKey.eudiLabelExpiryDate.localized()
        case "issuing_authority":
            return WalletStringKey.eudiLabelAuthority.localized()
        case "issuing_country", "issuing_country_for_display_eng":
            return WalletStringKey.eudiLabelIssuingCountry.localized()
        case "issuing_jurisdiction":
            return WalletStringKey.eudiLabelIssuingJurisdiction.localized()
        case "un_distinguishing_sign":
            return WalletStringKey.eudiLabelDistinguishingSign.localized()
        case "resident_country":
            return WalletStringKey.eudiLabelResidentCountry.localized()
        case "resident_state":
            return WalletStringKey.eudiLabelResidentState.localized()
        case "resident_city":
            return WalletStringKey.eudiLabelResidentCity.localized()
        case "resident_address":
            return WalletStringKey.eudiLabelResidentAddress.localized()
        case "resident_postal_code":
            return WalletStringKey.eudiLabelResidentPostalCode.localized()
        case "height":
            return WalletStringKey.eudiLabelHeight.localized()
        case "eye_colour":
            return WalletStringKey.eudiLabelEyeColour.localized()
        case "hair_colour":
            return WalletStringKey.eudiLabelHairColour.localized()
        case "weight":
            return WalletStringKey.eudiLabelWeight.localized()
        case "family_name_national_character":
            return WalletStringKey.eudiLabelNationalFamilyName.localized()
        case "given_name_national_character":
            return WalletStringKey.eudiLabelNationalGivenName.localized()
        default:
            return displayName
        }
    }

    private func name(document: MdlDocumentModel) -> String {
        [document.givenName?.value, document.familyName?.value]
            .compactMap { $0 }
            .joined(separator: " ")
    }

    private func fullNameValue(document: MdlDocumentModel) -> String? {
        let value = name(document: document)
        return value.isEmpty ? nil : value
    }

    private func fullname(document: MdlDocumentModel) -> String {
        [
            document.givenNameNationalCharacter?.value,
            document.familyNameNationalCharacter?.value
        ]
            .compactMap { $0 }
            .joined(separator: " ")
    }

    /// Convert sex integer to display string
    private func sexDisplay(document: MdlDocumentModel) -> String? {
        if let genderForDisplay = document.genderForDisplay?.value {
            return genderForDisplay
        }
        guard let sex = document.sex?.value else { return nil }
        switch sex.lowercased() {
        case "0": return WalletStringKey.documentGenderNotKnown.localized()
        case "1", "male", "m": return WalletStringKey.documentGenderMale.localized()
        case "2", "female", "f": return WalletStringKey.documentGenderFemale.localized()
        case "9": return WalletStringKey.documentGenderNotApplicable.localized()
        default: return sex
        }
    }

    private func sexTitle(document: MdlDocumentModel) -> String {
        if let genderForDisplay = document.genderForDisplay {
            return title(for: genderForDisplay, fallback: WalletStringKey.eudiLabelSex.localized())
        }
        return title(for: document.sex, fallback: WalletStringKey.eudiLabelSex.localized())
    }

    private func expirationDate(document: MdlDocumentModel) -> Date {
        DocumentExpiryResolver.resolveExpiry(
            primary: document.validUntilDate,
            fallbackString: document.expiryDate?.value
        )
    }

    private func categories(document: MdlDocumentModel) -> String? {
        let categories = document.drivingPrivileges?.drivingPrivileges.map(\.vehicleCategoryCode) ?? []
        let value = categories.joined(separator: ", ")
        return value.isEmpty ? nil : value
    }

    /// One block of rows per driving privilege: category, issue date, expiry date,
    /// and — when present — a comma-joined list of restriction codes
    /// (ISO 18013-5 `codes`, e.g. "01.06" corrective lenses, "78" auto only).
    /// Each code is rendered as `code` alone, or `code sign value` when both
    /// `sign` and `value` are present (e.g. `01.02 > 0.50` for eyeglass strength).
    private func drivingPrivilegeDetailItems(document: MdlDocumentModel) -> [DSTableItem] {
        let privileges = document.drivingPrivileges?.drivingPrivileges ?? []
        return privileges.flatMap { privilege -> [DSTableItem] in
            var rows: [DSTableItem] = [
                makeFieldItem(
                    label: WalletStringKey.eudiLabelCategory.localized(),
                    value: privilege.vehicleCategoryCode
                )
            ]
            if let issueDate = privilege.issueDate, !issueDate.isEmpty {
                let formatted = formattedDocumentTextDate(for: issueDate) ?? issueDate
                rows.append(makeFieldItem(
                    label: WalletStringKey.eudiLabelDateOfIssue.localized(),
                    value: formatted
                ))
            }
            if let expiryDate = privilege.expiryDate, !expiryDate.isEmpty {
                let formatted = formattedDocumentTextDate(for: expiryDate) ?? expiryDate
                rows.append(makeFieldItem(
                    label: WalletStringKey.eudiLabelExpiryDate.localized(),
                    value: formatted
                ))
            }
            if let restrictions = formattedRestrictions(for: privilege.codes) {
                rows.append(makeFieldItem(
                    label: WalletStringKey.eudiLabelRestrictions.localized(),
                    value: restrictions
                ))
            }
            return rows
        }
    }

    /// Format the privilege's `codes` array into a single comma-joined string.
    /// Returns nil when the codes array is nil, empty, or contains only entries
    /// that collapse to empty after trimming.
    private func formattedRestrictions(for codes: [DrivingPrivilegeCode]?) -> String? {
        guard let codes, !codes.isEmpty else { return nil }
        let formatted = codes.compactMap { code -> String? in
            let base = code.code.trimmingCharacters(in: .whitespaces)
            guard !base.isEmpty else { return nil }
            let sign = code.sign?.trimmingCharacters(in: .whitespaces) ?? ""
            let value = code.value?.trimmingCharacters(in: .whitespaces) ?? ""
            if !sign.isEmpty, !value.isEmpty {
                return "\(base) \(sign) \(value)"
            }
            return base
        }
        return formatted.isEmpty ? nil : formatted.joined(separator: ", ")
    }

    private func formattedExpiryDateForTicker(document: MdlDocumentModel) -> String {
        guard let value = document.expiryDate?.value else { return .empty }
        return formattedDocumentTextDate(for: value) ?? value
    }

    private func documentValidUntilTickerValue(document: MdlDocumentModel) -> String {
        WalletStringKey.documentValidUntilTicker.formattedLocalized(
            arguments: formattedExpiryDateForTicker(document: document)
        ) + " • "
    }

    private func formattedDocumentTextDate(for value: String?) -> String? {
        guard let value else { return nil }
        return AppDateFormatter.bestEffortReformat(
            value,
            preferredSources: [.yyyyMMdd, .ddMMyyyy, .iso8601, .dayMonthYearText],
            to: .dayMonthYearText
        )
    }

    private func formattedDocumentNumericDate(for value: String?) -> String? {
        guard let value else { return nil }
        return AppDateFormatter.bestEffortReformat(
            value,
            preferredSources: [.yyyyMMdd, .ddMMyyyy, .iso8601, .dayMonthYearText],
            to: .dayMonthYearNumeric
        )
    }
}
