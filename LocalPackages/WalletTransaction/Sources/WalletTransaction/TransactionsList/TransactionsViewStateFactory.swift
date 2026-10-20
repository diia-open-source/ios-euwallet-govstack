//
//  TransactionsViewStateFactory.swift
//

import Foundation
import DiiaCommonTypes
import DiiaUIComponents
import WalletCore
import WalletDomainModels

// MARK: - Action Types

enum TransactionsAction: String {
    case back
    case selectLog
}

// MARK: - Factory

public protocol TransactionsViewStateFactoryProtocol {
    func make(entries: [TransactionLogEntry]) -> DSConstructorModel
}

public struct TransactionsViewStateFactory: TransactionsViewStateFactoryProtocol {
    public init() {}

    public func make(entries: [TransactionLogEntry]) -> DSConstructorModel {
        let sortedEntries = entries.sorted { $0.createdAt > $1.createdAt }

        let body: [AnyCodable]
        if sortedEntries.isEmpty {
            body = [
                .component(.stubMessageMlc, DSStubMessageMlc(
                    icon: nil,
                    title: WalletStringKey.transactionLogStubTitle.localized(),
                    description: WalletStringKey.transactionLogStubDescription.localized(),
                    componentId: nil,
                    parameters: nil,
                    btnStrokeAdditionalAtm: nil
                ))
            ]
        } else {
            body = sortedEntries.enumerated().map { index, entry in
                let date = AppDateFormatter.string(from: entry.createdAt, style: .dayMonthYearHourMinute)
                let card = DSCardMlcV2Model(
                    componentId: "transaction_\(index)",
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
                    smallIconAtm: DSIconModel(
                        code: "ellipseArrowRight",
                        action: DSActionParameter(action: TransactionsAction.selectLog, resource: "\(entry.id)")
                    ),
                    smallIconAtmWithStates: nil,
                    attentionIconMessageMlc: nil,
                    action: DSActionParameter(action: TransactionsAction.selectLog, resource: "\(entry.id)")
                )
                return makeCardComponent(
                    card,
                    top: index == 0 ? nil : .medium,
                    side: .medium
                )
            }
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
            title: WalletStringKey.menuTitleTransactions.localized(),
            iconLeft: DSIconModel(.back, action: DSActionParameter(action: TransactionsAction.back)),
            isClosed: true
        ))
    }

    private func makeCardComponent(
        _ model: DSCardMlcV2Model,
        top: DSSizingType?,
        side: DSSizingType?
    ) -> AnyCodable {
        .componentWithPadding(.cardMlcV2, model, top: top, side: side)
    }
}
