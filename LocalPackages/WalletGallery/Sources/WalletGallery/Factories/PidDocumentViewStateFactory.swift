//
//  PidDocumentViewStateFactory.swift
//

import Foundation
import DiiaCommonTypes
import DiiaUIComponents
import WalletDocumentsCommonTypes
import WalletCore
import WalletDomainModels

public protocol PidDocumentViewStateFactoryProtocol {
    func make(document: PidDocumentModel) -> DSFullDocumentModel
}

public struct PidDocumentViewStateFactory: PidDocumentViewStateFactoryProtocol {
    public init() {}
    public func make(document: PidDocumentModel) -> DSFullDocumentModel {
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
                        document.signature.map { DSDocumentContent(image: $0.value, code: .signature) }
                    ].compactMap { $0 },
                    docData: DSDocData(
                        docName: WalletStringKey.eudiLabelPid.localized(),
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
    private func frontCardModel(document: PidDocumentModel) -> DSDocumentModel {
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
                            label: "\(document.birthDate?.displayName ?? WalletStringKey.eudiLabelBirthDate.localized()):",
                            value: value)
                        )
                    },
                    (document.nationalityForDisplay ?? document.nationality).map {
                        DSItemsModel(tableItemVerticalMlc: DSTableItemVerticalMlc(
                            label: "\($0.displayName):",
                            value: $0.value)
                        )
                    },
                    document.signature.map { _ in
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
            docButtonHeadingOrg: DSDocumentHeading(
                headingWithSubtitlesMlc: DSHeadingWithSubtitlesModel(
                    value: name(document: document),
                    subtitles: nil
                ),
                iconAtm: DSIconModel(
                    code: "ellipseKebab",
                    action: DSActionParameter(type: "ellipseMenu", subtype: "pid")
                )
            )
        )
    }

    // MARK: - Full Info
    private func fullInfo(document: PidDocumentModel) -> [AnyCodable] {
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
                            label: "\(title(for: document.birthDate, fallback: WalletStringKey.eudiLabelBirthDate.localized())):",
                            value: value)
                        )
                    },
                    document.signature.map { _ in
                        DSItemsModel(tableItemVerticalMlc: DSTableItemVerticalMlc(
                            valueImage: .signature)
                        )
                    }
                ].compactMap { $0 },
                headingWithSubtitlesMlc: DSHeadingWithSubtitlesModel(
                    value: name(document: document),
                    subtitles: nil
                )
            )),

            .component(.tableBlockOrg, DSTableBlockItemModel(
                tableMainHeadingMlc: nil,
                tableSecondaryHeadingMlc: nil,
                items: [
                    sexDisplay(document: document).map {
                        makeFieldItem(
                            label: sexTitle(document: document),
                            value: $0
                        )
                    },
                    (document.nationalityForDisplay ?? document.nationality).map {
                        makeFieldItem(
                            label: WalletStringKey.eudiLabelNationality.localized(),
                            value: $0.value
                        )
                    },
                    birthPlaceFormatted(document: document).map { value in
                        makeFieldItem(
                            label: title(for: document.birthPlace, fallback: WalletStringKey.eudiLabelBirthPlace.localized()),
                            value: value
                        )
                    }
                ].compactMap { $0 }
            )),

            .component(.tableBlockOrg, DSTableBlockItemModel(
                tableMainHeadingMlc: nil,
                tableSecondaryHeadingMlc: nil,
                items: [
                    personalAdministrativeNumberItem(document: document),
                    formattedDocumentTextDate(for: document.issuanceDate?.value).map { value in
                        makeFieldItem(
                            label: title(for: document.issuanceDate, fallback: WalletStringKey.eudiLabelIssuanceDate.localized()),
                            value: value
                        )
                    },
                    formattedDocumentTextDate(for: document.expiryDate?.value).map { value in
                        makeFieldItem(
                            label: title(for: document.expiryDate, fallback: WalletStringKey.eudiLabelExpiryDate.localized()),
                            value: value
                        )
                    },
                    document.issuingAuthority.map {
                        makeFieldItem(
                            label: title(for: $0, fallback: WalletStringKey.eudiLabelIssuanceAuthority.localized()),
                            value: $0.value
                        )
                    },
                    document.issuingCountry.map {
                        makeFieldItem(
                            label: title(for: $0, fallback: WalletStringKey.eudiLabelIssuingCountry.localized()),
                            value: $0.value
                        )
                    },
                    document.issuingJurisdiction.map {
                        makeFieldItem(
                            label: title(for: $0, fallback: WalletStringKey.eudiLabelIssuingJurisdiction.localized()),
                            value: $0.value
                        )
                    }
                ].compactMap { $0 }
            )),

            hasResidenceData(document: document) ? .component(.tableBlockOrg, DSTableBlockItemModel(
                tableMainHeadingMlc: nil,
                tableSecondaryHeadingMlc: nil,
                items: [
                    document.residentCountry.map {
                        makeFieldItem(
                            label: title(for: $0, fallback: WalletStringKey.eudiLabelResidentCountry.localized()),
                            value: $0.value
                        )
                    },
                    document.residentState.map {
                        makeFieldItem(
                            label: title(for: $0, fallback: WalletStringKey.eudiLabelResidentState.localized()),
                            value: $0.value
                        )
                    },
                    document.residentCity.map {
                        makeFieldItem(
                            label: title(for: $0, fallback: WalletStringKey.eudiLabelResidentCity.localized()),
                            value: $0.value
                        )
                    },
                    document.residentStreet.map {
                        makeFieldItem(
                            label: title(for: $0, fallback: WalletStringKey.eudiLabelResidentStreet.localized()),
                            value: $0.value
                        )
                    },
                    document.residentHouseNumber.map {
                        makeFieldItem(
                            label: title(for: $0, fallback: WalletStringKey.eudiLabelResidentHouseNumber.localized()),
                            value: $0.value
                        )
                    },
                    document.residentPostalCode.map {
                        makeFieldItem(
                            label: title(for: $0, fallback: WalletStringKey.eudiLabelResidentPostalCode.localized()),
                            value: $0.value
                        )
                    },
                    residentAddressFormatted(document: document).map { formatted in
                        makeFieldItem(
                            label: title(for: document.residentAddress, fallback: WalletStringKey.eudiLabelResidentAddress.localized()),
                            value: formatted
                        )
                    }
                ].compactMap { $0 }
            )) : nil,

            hasContactData(document: document) ? .component(.tableBlockOrg, DSTableBlockItemModel(
                tableMainHeadingMlc: nil,
                tableSecondaryHeadingMlc: nil,
                items: [
                    document.emailAddress.map {
                        makeFieldItem(
                            label: title(for: $0, fallback: WalletStringKey.eudiLabelEmailAddress.localized()),
                            value: $0.value
                        )
                    },
                    document.mobilePhoneNumber.map {
                        makeFieldItem(
                            label: title(for: $0, fallback: WalletStringKey.eudiLabelMobilePhoneNumber.localized()),
                            value: $0.value
                        )
                    }
                ].compactMap { $0 }
            )) : nil,

            extraFieldsSection(document: document)
        ].compactMap { $0 }
    }

    /// Birth-name fields are folded into the same trailing block as unknown
    /// fields rather than a dedicated section — these claims rarely appear and
    /// the issuer often sends them with placeholder values. JWT / SD-JWT
    /// envelope + issuer-metadata claims are noise to the end user and
    /// suppressed entirely.
    private static let suppressedUnknownFieldKeys: Set<String> = [
        "trust_anchor",
        "iat", "exp", "nbf", "sub", "iss",
        "vct", "_sd_alg", "cnf"
    ]

    private func extraFieldsSection(document: PidDocumentModel) -> AnyCodable? {
        let birthNameFields: [Field<String>] = [
            document.familyNameBirth,
            document.givenNameBirth
        ].compactMap { $0 }

        let filteredUnknown = document.unknownFields.filter {
            !Self.suppressedUnknownFieldKeys.contains($0.key)
        }

        let items: [DSTableItem] =
            birthNameFields.map { field in
                makeFieldItem(
                    label: title(for: field, fallback: field.displayName),
                    value: field.value
                )
            }
            + filteredUnknown.map { field in
                makeFieldItem(label: field.displayName, value: field.value)
            }

        guard !items.isEmpty else { return nil }
        return .component(.tableBlockOrg, DSTableBlockItemModel(
            tableMainHeadingMlc: nil,
            tableSecondaryHeadingMlc: nil,
            items: items
        ))
    }

    // MARK: - Domain Helpers

    /// Display name shown on the front card. Priority:
    /// 1. The issuer's OID4VCI credential-level `display.name` (`credential.displayName`),
    ///    so what the user sees matches what the issuer intended to publish.
    /// 2. Fallback — the local docType→string map (e.g. "PID (mDoc)" / "PID (SD-JWT)"),
    ///    used when the issuer published no display name.
    /// 3. Fallback — generic "National ID" string for unknown docTypes.
    private func documentDisplayName(document: PidDocumentModel) -> String {
        if let issuerName = document.displayName, !issuerName.isEmpty {
            return issuerName
        }
        guard let docType = document.docType,
              let walletDocType = WalletDocumentType(rawValue: docType) else {
            return WalletStringKey.eudiLabelNationalId.localized()
        }
        return walletDocType.displayName
    }

    private func hasResidenceData(document: PidDocumentModel) -> Bool {
        document.residentAddress != nil
            || document.residentStreet != nil
            || document.residentHouseNumber != nil
            || document.residentCity != nil
            || document.residentState != nil
            || document.residentPostalCode != nil
            || document.residentCountry != nil
    }

    private func hasContactData(document: PidDocumentModel) -> Bool {
        document.emailAddress != nil || document.mobilePhoneNumber != nil
    }

    private func hasAgeInfo(document: PidDocumentModel) -> Bool {
        document.ageInYears != nil || document.ageBirthYear != nil || document.ageOver18 != nil
    }

    private func hasBirthName(document: PidDocumentModel) -> Bool {
        document.familyNameBirth != nil
            || document.givenNameBirth != nil
    }

    private func hasPersonalInfoData(document: PidDocumentModel) -> Bool {
        document.nationalityForDisplay != nil
            || document.nationality != nil
            || document.genderForDisplay != nil
            || document.sex != nil
            || document.personalAdministrativeNumber != nil
            || document.administrativeNumber != nil
            || hasBirthName(document: document)
    }

    private func makeFieldItem(label: String, value: String) -> DSTableItem {
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
        case "birth_date", "birthdate":
            return WalletStringKey.eudiLabelBirthDate.localized()
        case "birth_place", "place_of_birth":
            return WalletStringKey.eudiLabelBirthPlace.localized()
        case "sex", "gender", "gender_for_display":
            return WalletStringKey.eudiLabelSex.localized()
        case "nationality", "nationalities", "nationality_for_display":
            return WalletStringKey.eudiLabelNationality.localized()
        case "issuance_date", "date_of_issuance":
            return WalletStringKey.eudiLabelIssuanceDate.localized()
        case "expiry_date", "date_of_expiry":
            return WalletStringKey.eudiLabelExpiryDate.localized()
        case "issuing_authority":
            return WalletStringKey.eudiLabelIssuanceAuthority.localized()
        case "issuing_country":
            return WalletStringKey.eudiLabelIssuingCountry.localized()
        case "issuing_jurisdiction":
            return WalletStringKey.eudiLabelIssuingJurisdiction.localized()
        case "personal_administrative_number", "administrative_number":
            return WalletStringKey.eudiLabelPersonalAdministrativeNumber.localized()
        case "resident_address", "formatted":
            return WalletStringKey.eudiLabelResidentAddress.localized()
        case "resident_street", "street_address":
            return WalletStringKey.eudiLabelResidentStreet.localized()
        case "resident_house_number", "house_number":
            return WalletStringKey.eudiLabelResidentHouseNumber.localized()
        case "resident_city", "locality":
            return WalletStringKey.eudiLabelResidentCity.localized()
        case "resident_state", "region":
            return WalletStringKey.eudiLabelResidentState.localized()
        case "resident_country", "country":
            return WalletStringKey.eudiLabelResidentCountry.localized()
        case "resident_postal_code", "postal_code":
            return WalletStringKey.eudiLabelResidentPostalCode.localized()
        case "email_address", "email":
            return WalletStringKey.eudiLabelEmailAddress.localized()
        case "mobile_phone_number", "phone_number":
            return WalletStringKey.eudiLabelMobilePhoneNumber.localized()
        default:
            return displayName
        }
    }

    private func personalAdministrativeNumberItem(document: PidDocumentModel) -> DSTableItem? {
        let field = document.personalAdministrativeNumber ?? document.administrativeNumber
        return field.map {
            makeFieldItem(
                label: title(for: $0, fallback: WalletStringKey.eudiLabelPersonalAdministrativeNumber.localized()),
                value: $0.value
            )
        }
    }

    private func sexDisplay(document: PidDocumentModel) -> String? {
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

    private func sexTitle(document: PidDocumentModel) -> String {
        if let genderForDisplay = document.genderForDisplay {
            return title(for: genderForDisplay, fallback: WalletStringKey.eudiLabelSex.localized())
        }
        return title(for: document.sex, fallback: WalletStringKey.eudiLabelSex.localized())
    }

    private func name(document: PidDocumentModel) -> String {
        [document.givenName?.value, document.familyName?.value]
            .compactMap { $0 }
            .joined(separator: " ")
    }

    private func fullNameValue(document: PidDocumentModel) -> String? {
        let value = name(document: document)
        return value.isEmpty ? nil : value
    }

    private func birthPlaceFormatted(document: PidDocumentModel) -> String? {
        if let value = document.birthPlace?.value, !value.isEmpty {
            return value
        }
        let components = [document.birthCity?.value, document.birthState?.value, document.birthCountry?.value]
            .compactMap { $0 }
        return components.isEmpty ? nil : components.joined(separator: ", ")
    }

    private func residentAddressFormatted(document: PidDocumentModel) -> String? {
        if let value = document.residentAddress?.value, !value.isEmpty {
            return value
        }
        var components: [String] = []
        if let street = document.residentStreet?.value {
            if let houseNumber = document.residentHouseNumber?.value {
                components.append("\(street) \(houseNumber)")
            } else {
                components.append(street)
            }
        }
        if let city = document.residentCity?.value { components.append(city) }
        if let state = document.residentState?.value { components.append(state) }
        if let postalCode = document.residentPostalCode?.value { components.append(postalCode) }
        if let country = document.residentCountry?.value { components.append(country) }
        return components.isEmpty ? nil : components.joined(separator: ", ")
    }

    private func expirationDate(document: PidDocumentModel) -> Date {
        DocumentExpiryResolver.resolveExpiry(
            primary: document.validUntilDate,
            fallbackString: document.expiryDate?.value
        )
    }

    private func formattedExpiryDateForTicker(document: PidDocumentModel) -> String {
        guard let value = document.expiryDate?.value else { return .empty }
        return formattedDocumentTextDate(for: value) ?? value
    }

    private func documentValidUntilTickerValue(document: PidDocumentModel) -> String {
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
}
