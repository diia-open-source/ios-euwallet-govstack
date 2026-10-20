import Foundation
import DiiaCommonTypes
import DiiaUIComponents
import WalletCore
import WalletDomainModels

enum SettingsScreenAction: String {
    case back
    case openDocsOrder
    case openChangePin
}

protocol SettingsViewStateFactoryProtocol {
    func make(items: [SettingsItemViewData]) -> DSConstructorModel
}

struct SettingsViewStateFactory: SettingsViewStateFactoryProtocol {
    func make(items: [SettingsItemViewData]) -> DSConstructorModel {
        DSConstructorModel(
            topGroup: [
                .component(.navigationPanelMlcV2, DSNavigationPanelV2(
                    componentId: nil,
                    title: WalletStringKey.menuTitleSettings.localized(),
                    iconLeft: DSIconModel(.back, action: DSActionParameter(action: SettingsScreenAction.back)),
                    isClosed: true
                ))
            ],
            body: items.enumerated().map { index, item in
                let showSeparator = index < items.count - 1
                switch item {
                case .action(let actionItem):
                    let model = SettingsActionRowModel(
                        componentId: actionItem.id,
                        title: actionItem.title,
                        iconName: actionItem.iconName,
                        action: DSActionParameter(action: actionItem.action),
                        showSeparator: showSeparator
                    )
                    return makeFeatureComponent(
                        key: SettingsActionRowBuilder.key,
                        model: model,
                        top: index == 0 ? nil : .medium,
                        side: .none
                    )
                case .toggle(let toggleItem):
                    let model = IconSwitchRowModel(
                        componentId: toggleItem.id,
                        id: toggleItem.id,
                        title: toggleItem.title,
                        iconName: toggleItem.iconName,
                        isOn: toggleItem.isOn,
                        showSeparator: showSeparator
                    )
                    return makeFeatureComponent(
                        key: IconSwitchRowBuilder.key,
                        model: model,
                        top: index == 0 ? nil : .medium,
                        side: .large
                    )
                }
            }
        )
    }

    private func makeFeatureComponent<Model: Encodable>(
        key: String,
        model: Model,
        top: DSSizingType?,
        side: DSSizingType?
    ) -> AnyCodable {
        .componentWithPadding(key: key, model: model, top: top, side: side)
    }
}

enum SettingsItemViewData {
    case action(SettingsActionItemViewData)
    case toggle(SettingsToggleItemViewData)
}

struct SettingsActionItemViewData {
    let id: String
    let title: String
    let iconName: String
    let action: SettingsScreenAction
}

struct SettingsToggleItemViewData {
    let id: String
    let title: String
    let iconName: String
    let isOn: Bool
}
