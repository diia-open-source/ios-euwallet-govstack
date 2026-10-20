import UIKit
import DiiaUIComponents
import WalletDomainModels

protocol QRCodeScannerView: ConstructorScreenViewProtocol {
    func apply(viewState: QRCodeScannerViewState)
    func startScanning()
    func stopScanning()
    func showQRError(message: String?)
    func showClosingAlert(title: String, message: String, actionTitle: String, action: @escaping () -> Void)
    func removeFromBackStackAfterPush()
}

final class QRCodeScannerViewController: ConstructorViewController {
    private let scannerService: QRCodeScannerCaptureServiceProtocol
    private let overlayView: QRCodeScannerOverlayView

    private var scannerPresenter: QRCodeScannerAction? {
        presenter as? QRCodeScannerAction
    }

    init(scannerService: QRCodeScannerCaptureServiceProtocol, images: QRCodeScannerImages) {
        self.scannerService = scannerService
        self.overlayView = QRCodeScannerOverlayView(images: images)
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didLoadConstructorView() {
        setupBackground(.color(.black))
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(overlayView)
        NSLayoutConstraint.activate([
            overlayView.topAnchor.constraint(equalTo: view.topAnchor),
            overlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupActions()
        bindScannerService()
    }

    private func setupActions() {
        overlayView.onBackTap = { [weak self] in
            self?.scannerPresenter?.close()
        }
    }

    private func bindScannerService() {
        scannerService.attach(to: overlayView.previewView)
        scannerService.onFailure = { [weak self] in
            self?.scannerPresenter?.handleScannerFailure()
        }
        scannerService.onCodeDetected = { [weak self] code in
            guard let self else { return }
            guard self.view.window != nil,
                  self.presentedViewController == nil
            else { return }

            self.scannerPresenter?.proceed(code: code)
        }
    }
}

extension QRCodeScannerViewController: QRCodeScannerView {
    func apply(viewState: QRCodeScannerViewState) {
        configure(model: viewState.constructorModel)
        overlayView.configure(viewState: viewState)
    }

    func startScanning() {
        scannerService.start()
    }

    func stopScanning() {
        scannerService.stop()
    }

    func showQRError(message: String?) {
        overlayView.setErrorMessage(message)
    }

    func showClosingAlert(title: String, message: String, actionTitle: String, action: @escaping () -> Void) {
        guard presentedViewController == nil else { return }

        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: actionTitle, style: .default, handler: { _ in
            action()
        }))
        present(alert, animated: true)
    }

    func removeFromBackStackAfterPush() {
        guard let navigationController else { return }

        let removeScannerFromStack = {
            navigationController.viewControllers = navigationController.viewControllers.filter { $0 !== self }
        }

        if let coordinator = transitionCoordinator {
            coordinator.animate(alongsideTransition: nil) { _ in
                removeScannerFromStack()
            }
        } else {
            DispatchQueue.main.async {
                removeScannerFromStack()
            }
        }
    }
}
