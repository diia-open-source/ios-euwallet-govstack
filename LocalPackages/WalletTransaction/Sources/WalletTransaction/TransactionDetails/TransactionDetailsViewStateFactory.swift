//
//  TransactionDetailsViewStateFactory.swift
//

import Foundation
import DiiaCommonTypes
import DiiaUIComponents
import WalletCore
import WalletDomainModels

// MARK: - Action Types

enum TransactionDetailsAction: String {
    case back
}

protocol TransactionDetailsViewStateFactoryProtocol {
    func make(entry: TransactionLogEntry, documents: [ParsedDocumentClaims]) -> DSConstructorModel
}

struct TransactionDetailsViewStateFactory: TransactionDetailsViewStateFactoryProtocol {

    func make(entry: TransactionLogEntry, documents: [ParsedDocumentClaims]) -> DSConstructorModel {
        let date = AppDateFormatter.string(from: entry.createdAt, style: .dayMonthYearHourMinute)
        var body: [AnyCodable] = [
            makeCardComponent(DSCardMlcV2Model(
                componentId: "details_card",
                chipStatusAtm: DSCardStatusChipModel(
                    code: "",
                    name: entry.status.displayText,
                    type: TransactionStatusMapper.chipType(for: entry.status),
                    componentId: nil
                ),
                label: entry.title,
                rightLabel: date,
                descriptions: nil,
                rows: nil,
                chips: [
                    DSCardStatusChipMlc(chipStatusAtm: .init(
                        code: "",
                        name: entry.kind.displayLabel,
                        type: .white,
                        componentId: nil
                    ))
                ],
                iconUrlAtm: nil,
                smallIconAtm: nil,
                smallIconAtmWithStates: nil,
                attentionIconMessageMlc: nil,
                action: nil
            ), side: .medium)
        ]

        if documents.isEmpty {
            let missingTitle = entry.documentTitle ?? entry.title
            body.append(makeMissingDocumentBlock(title: missingTitle))
        } else {
            body.append(contentsOf: documents.map(makeDocumentTable))
        }

        return DSConstructorModel(
            topGroup: [makeNavigationPanel()],
            body: body
        )
    }

    // MARK: - Helpers
    private func makeNavigationPanel() -> AnyCodable {
        .component(.navigationPanelMlcV2, DSNavigationPanelV2(
            componentId: nil,
            title: WalletStringKey.transactionDetailsTitle.localized(),
            iconLeft: DSIconModel(.back, action: DSActionParameter(action: TransactionDetailsAction.back)),
            isClosed: true
        ))
    }

    private func makeMissingDocumentBlock(title: String) -> AnyCodable {
        .componentWithPadding(.tableBlockOrgV2, DSTextBlockV2Model(
            componentId: "transaction_details_document_not_found",
            chipStatusAtm: nil,
            tableMainHeadingMlc: DSTableHeadingItemModel(
                label: title,
                description: nil
            ),
            tableSecondaryHeadingMlc: nil,
            items: [],
            attentionIconMessageMlc: DSAttentionIconMessageMlc(
                componentId: "transaction_details_document_not_found_message",
                smallIconAtm: DSIconModel(.attentionBlackRoundSmall),
                text: WalletStringKey.transactionDetailsDocumentNotFoundMessage.localized(),
                parameters: nil,
                backgroundMode: .note,
                expanded: nil
            )
        ), top: .medium, side: .medium)
    }

    private func makeDocumentTable(_ doc: ParsedDocumentClaims) -> AnyCodable {
        var items: [AnyCodable] = doc.flatItems.map { (label, value) in
            .component(.textLabelMlc, DSTextContainerData(
                componentId: nil,
                text: "\(label):\n\(value)",
                label: nil,
                parameters: nil
            ))
        }

        for nested in doc.nestedItems {
            items.append(.component(.accordionOrg, DSAccordionOrgModel(
                heading: nested.title,
                states: DSAccordionOrgState(
                    isExpanded: false,
                    expandedIcon: DSIconModel(.chevronUp),
                    collapsedIcon: DSIconModel(.chevronDown)
                ),
                expandedContent: DSAccordionOrgExpandedContentModel(
                    items: nested.items.map { (label, value) in
                        .component(.tableItemHorizontalMlc, DSTableItemHorizontalMlc(
                            label: "\(label):",
                            value: value
                        ))
                    }
                )
            )))
        }

        let tableViewModel = DSTextBlockV2Model(
            componentId: "doc_table_\(doc.displayName)",
            chipStatusAtm: nil,
            tableMainHeadingMlc: DSTableHeadingItemModel(
                label: doc.displayName,
                description: WalletStringKey.trascationLogDataShared.localized()
            ),
            tableSecondaryHeadingMlc: nil,
            items: items,
            attentionIconMessageMlc: nil
        )
        return .component(.tableBlockOrgV2, tableViewModel)
    }

    private func makeCardComponent(
        _ model: DSCardMlcV2Model,
        top: DSSizingType? = nil,
        side: DSSizingType?
    ) -> AnyCodable {
        .componentWithPadding(.cardMlcV2, model, top: top, side: side)
    }
}
