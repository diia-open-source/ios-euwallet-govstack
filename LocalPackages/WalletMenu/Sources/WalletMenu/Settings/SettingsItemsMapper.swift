import Foundation
import WalletAuthorizationPinCode
import WalletCore
import WalletDomainModels

enum SettingsRowID: String {
    case docsOrder
    case changePin
}

enum SettingsToggleRowID: String {
    case biometryToggle
}

protocol SettingsItemsMapperProtocol {
    func makeItems(biometryService: BiometryAuthServiceProtocol) -> [SettingsItemViewData]
}

struct SettingsItemsMapper: SettingsItemsMapperProtocol {
    func makeItems(biometryService: BiometryAuthServiceProtocol) -> [SettingsItemViewData] {
        var items: [SettingsItemViewData] = [
            .action(SettingsActionItemViewData(
                id: SettingsRowID.docsOrder.rawValue,
                title: WalletStringKey.settingsDocsOrder.localized(),
                iconName: "reorder",
                action: .openDocsOrder
            )),
            .action(SettingsActionItemViewData(
                id: SettingsRowID.changePin.rawValue,
                title: WalletStringKey.menuChangePin.localized(),
                iconName: "edit",
                action: .openChangePin
            ))
        ]

        if biometryService.isBiometryAvailable {
            let biometryType = biometryService.biometryType
            let title = WalletStringKey.settingsBiometryToggle.localized(with: biometryType.displayName)
            let iconName = biometryType == .faceID ? "faceid" : "touchid"

            items.append(.toggle(SettingsToggleItemViewData(
                id: SettingsToggleRowID.biometryToggle.rawValue,
                title: title,
                iconName: iconName,
                isOn: biometryService.isBiometryEnabled
            )))
        }

        return items
    }
}
