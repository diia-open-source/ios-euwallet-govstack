//
//  WalletDisclosureRequestAdapter.swift
//

import Foundation
import DiiaCommonTypes
import DiiaUIComponents
import WalletCore
import WalletDomainModels

public struct WalletDisclosureRequestAdapter {
    private let relyingParty: String
    private let docValues: DocValues

    init(relyingParty: String, docValues: DocValues) {
        self.relyingParty = relyingParty
        self.docValues = docValues
    }

    public func getContructorModel() -> DSConstructorModel {
        return DSConstructorModel(
            topGroup: topGroup(),
            body: body(),
            bottomGroup: bottomGroup()
        )
    }

    // MARK: - Private Methods
    private func topGroup() -> [AnyCodable] {
        return [
            .component(.navigationPanelMlcV2, DSNavigationPanelV2(
                componentId: nil,
                title: WalletStringKey.sharingScreenTitle.localized(),
                iconLeft: DSIconModel(.back, action: .init(type: "back")),
                isClosed: true
            ))
        ]
    }

    private func body() -> [AnyCodable] {
        return docValues.reduce(into: [
            .component(.titleLabelMlc, DSTitleLabelMlc(
                label: WalletStringKey.sharingScreenSubtitle.localized(),
                componentId: nil
            )),
            .componentWithPadding(key: DSAttentionIconMessageBuilder.key, model: DSAttentionIconMessageMlc(
                componentId: "sharing_screen_data_optional_message",
                smallIconAtm: DSIconModel(.attentionBlackRoundSmall),
                text: WalletStringKey.sharingScreenDataOptionalInfo.localized(),
                parameters: nil,
                backgroundMode: .note,
                expanded: nil
            ), top: .large, side: .large),
            .componentWithPadding(key: DSTextViewBuilder.key, model: DSTextContainerData(
                componentId: nil,
                text: WalletStringKey.sharingScreenDescription.formattedLocalized(arguments: relyingParty),
                label: nil
            ), top: .large)
        ]) { partialResult, docValue in
            partialResult.append(mapToBackgroundWhiteOrg(
                docNumber: docValue.key,
                docItems: docValue.value
            ))
        }
    }

    private func bottomGroup() -> [AnyCodable] {
        return [
            .component(.btnPrimaryDefaultAtm, DSButtonModel(
                label: WalletStringKey.sharingScreenButton.localized(),
                action: .init(type: "send_selective_disclosure"),
                componentId: nil
            ))
        ]
    }

    private func mapToBackgroundWhiteOrg(
        docNumber: String,
        docItems: [String: DocItemValue]
    ) -> AnyCodable {
        let headingLabel = docItems.first?.value.documentDisplayName ?? documentName(for: docItems.first?.value.docType)
        let items: [AnyCodable] = docItems.reduce(into: [
            .component(.tableMainHeadingMlc, DSTableHeadingItemModel(
                label: headingLabel
            ))
        ]) { partialResult, docItem in
            partialResult.append(mapToTableItemCheckboxMlc(
                docNumber: docNumber,
                elementIdentifier: docItem.key,
                docItem: docItem.value
            ))
        }
        return .component(.backgroundWhiteOrg, DSBackgroundWhiteOrgModel(
            componentId: UUID().uuidString,
            id: "",
            items: items
        ))
    }

    private func mapToTableItemCheckboxMlc(
        docNumber: String,
        elementIdentifier: String,
        docItem: DocItemValue
    ) -> AnyCodable {
        return .component(.tableItemCheckboxMlc, DSTableItemCheckboxModel(
            componentId: nil,
            inputCode: elementIdentifier + "/" + docNumber,
            mandatory: false,
            rows: [
                DSTableItemCheckboxRowModel(
                    textLabelAtm: DSTextLabelAtmModel(
                        mode: .primary,
                        label: docItem.displayName.title,
                        value: docItem.valueName
                    )
                ),
                docItem.displayName.subtitle.map {
                    DSTableItemCheckboxRowModel(
                        textLabelAtm: DSTextLabelAtmModel(
                            mode: .secondary,
                            label: $0,
                            value: nil
                        )
                    )
                }
            ].compactMap { $0 },
            isSelected: true,
            isNotFullSelected: nil,
            dataJson: nil
        ))
    }

    private func documentName(for docType: String?) -> String {
        switch docType {
        case "eu.europa.ec.eudi.pid.1", "urn:eudi:pid:1":
            return DocType.pidDocument.name
        case "org.iso.18013.5.1.mDL":
            return DocType.mdlDocument.name
        default:
            return WalletStringKey.sharingUnknownDocument.localized()
        }
    }
}
