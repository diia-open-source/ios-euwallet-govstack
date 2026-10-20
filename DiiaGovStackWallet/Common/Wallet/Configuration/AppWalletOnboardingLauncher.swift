import UIKit
import DiiaMVPModule
import DiiaCommonTypes
import WalletCore
import WalletDomainModels
import WalletScannerBarcode
import WalletIssuing

/// Bridges the wallet sharing flow's "no wallet yet, take the user to create one"
/// branch to the app's `DocumentsCollectionContextImpl` + `WalletOnboardingModule`.
struct AppWalletOnboardingLauncher: WalletOnboardingLaunching {
    func presentOnboardingFlow(in view: BaseView, flowCoordinator: FlowCoordinatorProtocol) {
        let documentsContext = DocumentsCollectionContextImpl(
            qrCodeScannerModuleFactory: QRCodeScannerModuleFactory(images: .default)
        )
        view.open(module: documentsContext.createDocumentListModule(
            onDocumentSelected: { selectedDocumentType in
                view.open(module: WalletOnboardingModule(
                    documentType: selectedDocumentType,
                    backgroundImage: R.image.light_background.image,
                    flowCoordinator: flowCoordinator
                ))
            }
        ))
    }
}
