//
//  MenuViewStateFactory.swift
//

import Foundation
import DiiaCommonTypes
import DiiaUIComponents
import WalletCore
import WalletDomainModels

// MARK: - Action Types

enum MenuScreenAction: String {
    case back
    case openTransactions
    case openScanQR
    case openSettings
    case logout
}

// MARK: - Factory

public protocol MenuViewStateFactoryProtocol {
    func make(version: String) -> DSConstructorModel
}

public struct MenuViewStateFactory: MenuViewStateFactoryProtocol {

    public init() {}

    public func make(version: String) -> DSConstructorModel {
        return DSConstructorModel(
            topGroup: [
                .component(.topGroupOrg, DSTopGroupOrg(
                    titleGroupMlc: DSTopGroupMlc(
                        heroText: WalletStringKey.mainScreenMenu.localized(),
                        label: WalletStringKey.menuVersion.formattedLocalized(arguments: version),
                        hideBackButton: true
                    )
                ))
            ],
            body: [
                makeListSection(
                    icon: .history,
                    title: WalletStringKey.menuTitleTransactions.localized(),
                    action: .openTransactions,
                    top: .large
                ),
                makeListSection(
                    icon: .qrScan,
                    title: WalletStringKey.menuTitleScanQr.localized(),
                    action: .openScanQR,
                    top: .large
                ),
                makeListSection(
                    icon: .settings,
                    title: WalletStringKey.menuTitleSettings.localized(),
                    action: .openSettings,
                    top: .large
                ),
                .component(.spacerAtm, SpacerAtm(value: .medium)),
                makeButton(
                    DSButtonModel(
                        label: WalletStringKey.menuLogout.localized(),
                        action: DSActionParameter(action: MenuScreenAction.logout),
                        componentId: nil
                    ),
                    top: .large
                )
            ]
        )
    }

    // MARK: - Helpers
    private func makeListSection(
        icon: DSIconKey,
        title: String,
        action: MenuScreenAction,
        top: DSSizingType?
    ) -> AnyCodable {
        let model = DSListGroup(items: [
            DSListGroupItem(
                iconLeft: DSIconModel(icon),
                label: title,
                action: DSActionParameter(action: action)
            )
        ])
        return .componentWithPadding(.listItemGroupOrg, model, top: top)
    }

    private func makeButton(
        _ model: DSButtonModel,
        top: DSSizingType?
    ) -> AnyCodable {
        .componentWithPadding(.btnPrimaryDefaultAtm, model, top: top)
    }
}
