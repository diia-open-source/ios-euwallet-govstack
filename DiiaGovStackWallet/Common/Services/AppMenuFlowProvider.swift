import UIKit
import DiiaMVPModule
import WalletAuthorizationPinCode
import WalletScannerBarcode
import WalletGallery
import WalletCore
import WalletDomainModels
import WalletMenu

/// App-side composition root for the menu / settings flow's outward navigation.
///
/// `MenuFlowProviding` lives in WalletMenu's `Common/`; the host wires this adapter into
/// `MenuModule.init(flowProvider:)` so the package never reaches for app singletons
/// (WalletQRScannerHelper, ServicesProvider, DocumentReorderingService, etc.) directly.
final class AppMenuFlowProvider: MenuFlowProviding {
    private let qrCodeScannerModuleFactory: QRCodeScannerModuleFactoryProtocol

    init(qrCodeScannerModuleFactory: QRCodeScannerModuleFactoryProtocol) {
        self.qrCodeScannerModuleFactory = qrCodeScannerModuleFactory
    }

    func presentQRScanner(in view: BaseView) {
        CameraAccessChecker.askCameraAccess(permissionDeniedHandler: AccessHelper.cameraPermissionDeniedHandler) { [weak self] granted in
            guard granted, let self else { return }
            let delegate = WalletQRScannerHelper(presentingView: view)
            view.open(module: self.qrCodeScannerModuleFactory.make(delegate: delegate))
        }
    }

    func performLogout() {
        ServicesProvider.shared.authService.logout()
    }

    func openDocsOrder(in view: BaseView) {
        view.open(module: DocumentsReorderingModule(
            orderService: DocumentReorderingService.shared,
            documentsProvider: DocumentsReorderingDocumentsProvider(),
            viewStateFactory: DocumentsReorderingViewStateFactory(),
            backgroundImage: R.image.light_background.image
        ))
    }

    func openChangePin(in view: BaseView) {
        view.open(module: ChangePincodeModule(
            pinCodeLength: AppConstants.defaultPinCodeLength,
            context: ChangePincodeModuleContext.create()
        ))
    }
}
