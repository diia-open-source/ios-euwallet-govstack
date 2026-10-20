import DiiaUIComponents
import WalletCore
import WalletDomainModels

protocol QRCodeScannerAction: ConstructorScreenPresenter {
    func proceed(code: String)
    func restart()
    func close()
    func handleScannerFailure()
}

final class QRCodeScannerPresenter: QRCodeScannerAction {
    unowned var view: QRCodeScannerView
    private var isFinished = false
    // Owned strongly: call sites often pass a throwaway helper (e.g. a local
    // `WalletQRScannerHelper` created just before presenting). A weak reference
    // let that helper deallocate immediately, so detected codes were silently
    // dropped (`proceed` saw a nil delegate). The handler only holds a weak
    // `presentingView` and never points back here, so there is no retain cycle.
    private let delegate: QRScannerDelegate?
    private let viewStateFactory: QRCodeScannerViewStateFactoryProtocol
    private var viewState: QRCodeScannerViewState?
    
    init(
        view: QRCodeScannerView,
        delegate: QRScannerDelegate?,
        viewStateFactory: QRCodeScannerViewStateFactoryProtocol
    ) {
        self.view = view
        self.delegate = delegate
        self.viewStateFactory = viewStateFactory
    }
    
    func configureView() {
        let viewState = viewStateFactory.make()
        self.viewState = viewState
        view.apply(viewState: viewState)
        view.showQRError(message: nil)
    }
    
    func restart() {
        isFinished = false
        view.showQRError(message: nil)
        view.startScanning()
    }

    func proceed(code: String) {
        if isFinished { return }

        view.stopScanning()
        guard let result = delegate?.process(code: code, in: view) else {
            view.startScanning()
            return
        }
        switch result {
        case .success(let removeScannerFromStack):
            isFinished = true
            view.showQRError(message: nil)
            if removeScannerFromStack {
                view.removeFromBackStackAfterPush()
            }
        case .error(let message):
            view.showQRError(message: message)
            view.startScanning()
        case .none:
            view.showQRError(message: nil)
            view.startScanning()
        }
    }

    func close() {
        view.stopScanning()
        view.closeModule(animated: true)
    }

    func handleScannerFailure() {
        guard let viewState else { return }
        view.stopScanning()

        view.showClosingAlert(
            title: viewState.closeAlertTitle,
            message: viewState.closeAlertMessage,
            actionTitle: viewState.closeAlertActionTitle,
            action: { [weak self] in
                self?.close()
            }
        )
    }

    func handleEvent(event: ConstructorItemEvent) { }

    func onViewDidAppear() {
        restart()
    }
}
