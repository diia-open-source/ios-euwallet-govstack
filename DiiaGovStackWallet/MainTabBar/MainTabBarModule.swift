import UIKit
import DiiaMVPModule
import WalletScannerBarcode
import WalletCore
import WalletDomainModels
       
final class MainTabBarModule: BaseModule {
    private let view: MainTabBarViewController
    private let presenter: MainTabBarPresenter
    
    init(qrCodeScannerModuleFactory: QRCodeScannerModuleFactoryProtocol) {
        view = MainTabBarViewController()
        presenter = MainTabBarPresenter(
            view: view,
            qrCodeScannerModuleFactory: qrCodeScannerModuleFactory
        )
        view.presenter = presenter
    }

    func viewController() -> UIViewController {
        return view
    }
}
