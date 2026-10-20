import UIKit
import DiiaMVPModule
import DiiaUIComponents
import DiiaCommonServices
import WalletAuthorizationPinCode

public final class SettingsModule: BaseModule {
    private let view: ConstructorViewController
    private let presenter: SettingsPresenter

    public init(
        flowProvider: MenuFlowProviding,
        biometryService: BiometryAuthServiceProtocol
    ) {
        view = ConstructorViewController()
        let fabric = DSViewFabric()
        fabric.setBuilder(SettingsActionRowBuilder())
        fabric.setBuilder(IconSwitchRowBuilder())
        view.setFabric(fabric)
        presenter = SettingsPresenter(
            view: view,
            biometryService: biometryService,
            viewStateFactory: SettingsViewStateFactory(),
            itemsMapper: SettingsItemsMapper(),
            flowProvider: flowProvider
        )
        view.presenter = presenter
    }

    public func viewController() -> UIViewController {
        return view
    }
}
