import UIKit
import DiiaMVPModule
import WalletCore
import WalletDomainModels

public struct QRCodeScannerModuleFactory: QRCodeScannerModuleFactoryProtocol {
    public let images: QRCodeScannerImages

    public init(images: QRCodeScannerImages = QRCodeScannerImages()) {
        self.images = images
    }

    public func make(delegate: QRScannerDelegate?) -> BaseModule {
        QRCodeScannerModule(delegate: delegate, images: images)
    }
}

final class QRCodeScannerModule: BaseModule {
    private let view: QRCodeScannerViewController
    private let presenter: QRCodeScannerPresenter

    init(
        delegate: QRScannerDelegate? = nil,
        images: QRCodeScannerImages,
        scannerService: QRCodeScannerCaptureServiceProtocol = QRCodeScannerCaptureService(),
        viewStateFactory: QRCodeScannerViewStateFactoryProtocol = QRCodeScannerViewStateFactory()
    ) {
        view = QRCodeScannerViewController(scannerService: scannerService, images: images)
        presenter = QRCodeScannerPresenter(
            view: view,
            delegate: delegate,
            viewStateFactory: viewStateFactory
        )
        view.presenter = presenter
    }

    func viewController() -> UIViewController {
        return view
    }
}
