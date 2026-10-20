//
//  DocumentsQRPresenter.swift
//

import UIKit
import DiiaMVPModule
import DiiaUIComponents
import DiiaCommonTypes
import WalletCore
import WalletDomainModels

protocol DocumentsQRAction: BasePresenter {
    func handleCloseAction()
}

final class DocumentsQRPresenter: DocumentsQRAction {

    // MARK: - Properties
    unowned var view: DocumentsQRView

    private let sessionManager: WalletProximitySessionManaging

    private let onClose: Callback?

    // MARK: - Init
    init(view: DocumentsQRView, onClose: Callback? = nil) {
        self.view = view
        self.onClose = onClose
        self.sessionManager = WalletDependencies.makeProximitySession()
        self.sessionManager.delegate = self
    }

    // MARK: - Public Methods
    func configureView() {
        sessionManager.startProximityPresentation()
    }
    
    func handleCloseAction() {
        sessionManager.cancelPresentation()
        finishQR()
    }

    // MARK: - Navigation
    private func openDisclosureScreen(request: PresentationRequest) {
        view.open(module: WalletProximitySharingModule(
            request: request,
            sessionManager: sessionManager
        ))
        finishQR()
    }

    private func finishQR() {
        view.dismissQR()
        onClose?()
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

// MARK: - ProximitySessionDelegate
extension DocumentsQRPresenter: WalletProximitySessionDelegate {
    public func didGenerateQRCode(_ payload: String) {
        view.configureQR(with: payload)
    }

    func didReceiveRequest(_ request: PresentationRequest) {
        openDisclosureScreen(request: request)
    }

    public func didFinishPresentation() {
        finishQR()
    }

    public func didReceiveError(
        _ error: PresentationError?,
        kind: WalletProximityErrorKind?
    ) {
        // The verifier sent a request the wallet can't satisfy because it holds no mDoc-format document.
        // Proximity (ISO 18013-5 BLE) can only present mDocs, so a wallet with only an SD-JWT PID hits this.
        // Show a dedicated message with a Cancel button instead of the generic "Go to Settings" error.
        if error?.code == .noDocumentsAvailable {
            view.showQRError(
                title: WalletStringKey.sharingNoMdocTitle.localized(),
                message: WalletStringKey.sharingNoMdocDescription.localized(),
                buttonTitle: WalletStringKey.generalCancel.localized(),
                buttonAction: { [weak self] in self?.handleCloseAction() }
            )
            return
        }

        // The verifier requested a document type the wallet doesn't hold (BLE `isValidRequest == false`).
        // No in-app action resolves this, so show only the title with no subtitle and no button — the close (X) control still dismisses.
        if error?.code == .credentialNotFound {
            view.showQRError(
                title: WalletStringKey.sharingErrorTitle.localized(),
                message: "",
                buttonTitle: nil,
                buttonAction: nil
            )
            return
        }

        let errorContent = Constants.bluetoothErrorContent(for: error?.description, kind: kind)
        view.showQRError(
            title: errorContent.title,
            message: errorContent.message,
            buttonTitle: WalletStringKey.eudiQrBluetoothSettingsButton.localized(),
            buttonAction: { [weak self] in self?.openSettings() }
        )
    }
}

// MARK: - Constants
private extension DocumentsQRPresenter {
    enum Constants {
        static func bluetoothErrorContent(
            for errorDescription: String?,
            kind: WalletProximityErrorKind?
        ) -> (title: String, message: String) {
            switch kind {
            case .accessRequired:
                return (
                    title: WalletStringKey.eudiQrBluetoothAccessRequiredTitle.localized(),
                    message: WalletStringKey.eudiQrBluetoothAccessRequiredDescription.localized()
                )
            case .turnedOff:
                return (
                    title: WalletStringKey.eudiQrBluetoothTurnOnTitle.localized(),
                    message: WalletStringKey.eudiQrBluetoothTurnOnDescription.localized()
                )
            case .connectionLost, .none:
                return (
                    title: WalletStringKey.sharingErrorTitle.localized(),
                    message: errorDescription ?? WalletStringKey.sharingErrorDescriptionDefault.localized()
                )
            }
        }
    }
}
