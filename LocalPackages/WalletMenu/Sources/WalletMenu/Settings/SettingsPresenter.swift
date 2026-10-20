import DiiaMVPModule
import WalletAuthorizationPinCode
import DiiaUIComponents
import DiiaCommonServices
import DiiaCommonTypes
import WalletCore
import WalletDomainModels

final class SettingsPresenter: ConstructorScreenPresenter {

    // MARK: - Properties
    unowned var view: ConstructorScreenViewProtocol
    private let biometryService: BiometryAuthServiceProtocol
    private let viewStateFactory: SettingsViewStateFactoryProtocol
    private let itemsMapper: SettingsItemsMapperProtocol
    private let flowProvider: MenuFlowProviding

    // MARK: - Init
    init(
        view: ConstructorScreenViewProtocol,
        biometryService: BiometryAuthServiceProtocol,
        viewStateFactory: SettingsViewStateFactoryProtocol,
        itemsMapper: SettingsItemsMapperProtocol,
        flowProvider: MenuFlowProviding
    ) {
        self.view = view
        self.biometryService = biometryService
        self.viewStateFactory = viewStateFactory
        self.itemsMapper = itemsMapper
        self.flowProvider = flowProvider
    }

    func configureView() {
        view.configure(model: viewStateFactory.make(items: itemsMapper.makeItems(biometryService: biometryService)))
    }

    func handleEvent(event: ConstructorItemEvent) {
        if case .customEvent(let customEvent) = event {
            handleCustomEvent(customEvent)
            return
        }

        guard let action = event.actionParameters(),
              let settingsAction = SettingsScreenAction(rawValue: action.type)
        else { return }

        switch settingsAction {
        case .back:
            view.closeModule(animated: true)
        case .openDocsOrder:
            flowProvider.openDocsOrder(in: view)
        case .openChangePin:
            flowProvider.openChangePin(in: view)
        }
    }

    private func handleCustomEvent(_ event: CustomConstructorEvent) {
        guard let eventCode = IconSwitchRowEventCode(rawValue: event.code) else {
            return
        }

        switch eventCode {
        case .toggleChanged:
            guard let rowIdValue = event.payload[IconSwitchRowEventPayload.id] as? String,
                  let rowId = SettingsToggleRowID(rawValue: rowIdValue)
            else {
                return
            }

            guard let isOn = event.payload[IconSwitchRowEventPayload.isOn] as? Bool else {
                return
            }

            switch rowId {
            case .biometryToggle:
                biometryService.setBiometryEnabled(isOn)
            }
        }
    }
}
