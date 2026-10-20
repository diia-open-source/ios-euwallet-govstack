//
//  WalletRemoteSharingPresenter.swift
//

import UIKit
import DiiaMVPModule
import DiiaCommonTypes
import DiiaUIComponents
import DiiaCommonServices
import WalletAuthorizationPinCode
import WalletDocumentsCore
import WalletCore
import WalletDomainModels

final class WalletRemoteSharingPresenter: ConstructorScreenPresenter {
    
    // MARK: - Properties
    unowned var view: ConstructorScreenViewProtocol
    
    private let flowCoordinator: FlowCoordinatorProtocol
    private let remoteSessionManager: WalletRemoteSessionManaging = WalletDependencies.makeRemoteSession()
    private let sharingDataHandler = WalletSharingDataHandler()
    private let revocationService: DocumentRevocationService

    private let link: String
    private let redirectCallback: ((String) -> Void)?
    private var redirectUrl: String?
    private var buttonViewModel: DSLoadingButtonViewModel?

    // MARK: - Init
    init(
        view: ConstructorScreenViewProtocol,
        link: String,
        redirectCallback: ((String) -> Void)?,
        revocationService: DocumentRevocationService = WalletDependencies.walletLifecycle.revocationService
    ) {
        self.view = view
        self.link = link
        self.redirectCallback = redirectCallback
        self.revocationService = revocationService
        let flowCoordinator = PublicServiceFlowCoordinator(rootView: nil)
        self.flowCoordinator = flowCoordinator
        flowCoordinator.restartCallback = { [weak self] in
            self?.configureView()
        }
        self.remoteSessionManager.delegate = self
    }

    deinit {
        remoteSessionManager.cancelPresentation()
    }

    // MARK: - Public Methods
    func configureView() {
        fetchStoredDocuments()
    }
    
    func handleEvent(event: ConstructorItemEvent) {
        switch event {
        case .inputChanged(let inputModel):
            if case let .bool(isSelected) = inputModel.inputData, !isSelected {
                guard sharingDataHandler.getDocItem(forInputCode: inputModel.inputCode) != nil else { return }

                showWarningMessage(WalletStringKey.sharingSelectiveDataWarning.localized())
            }
            guard !view.getInputData().isEmpty else {
                buttonViewModel?.state.value = .disabled
                return
            }
            view.inputFieldsWasUpdated()
        case .onComponentConfigured(let type):
            if case let .loadingButton(viewModel) = type {
                self.buttonViewModel = viewModel
            }
        default:
            guard let action = event.actionParameters() else { return }
            actionTapped(action: action)
        }
    }
    
    // MARK: - Private Methods
    private func fetchStoredDocuments() {
        view.setInnerTridentLoading(.loading)

        // Pre-load issuer metadata for user-friendly error messages
        WalletDependencies.walletErrorFormatter.preloadMetadata()

        guard WalletDependencies.walletController.isWalletActivated else {
            handleAlert(alert: Constants.noDocumentsAlert)
            view.setInnerTridentLoading(.ready)
            return
        }
        remoteSessionManager.startRemotePresentation(urlString: link)
    }
    
    private func actionTapped(action: DSActionParameter) {
        switch action.type {
        case Constants.sendSelectiveDisclosureAction:
            let inputData = view.getInputData()
            buttonViewModel?.state.value = .loading
            let selectedItems = sharingDataHandler.transformAnyCodableToRequest(input: inputData)
            if selectedItems.isEmpty {
                handleAlert(alert: Constants.makeErrorAlert())
                return
            }
            showAuthBeforeSend { [weak self] in
                self?.remoteSessionManager.sendResponse(disclosedItems: selectedItems)
            } onCancel: { [weak self] in
                self?.buttonViewModel?.state.value = .enabled
            }
        case Constants.backAction:
            remoteSessionManager.cancelPresentation()
            view.closeModule(animated: true)
        default:
            break
        }
    }
    
    private func processRequest(_ request: PresentationRequest) {
        guard !request.items.isEmpty else {
            handleAlert(alert: Constants.noDocumentsAlert)
            view.setInnerTridentLoading(.ready)
            return
        }

        guard request.isTrusted else {
            handleAlert(alert: Constants.untrustedVerifierAlert)
            view.setInnerTridentLoading(.ready)
            return
        }

        let revokedDocIds = request.items.filter { item in
            revocationService.isRevoked(documentId: item.id)
        }.map { $0.id }

        if !revokedDocIds.isEmpty {
            handleAlert(alert: Constants.noDocumentsAlert)
            return
        }

        let constructorModel = sharingDataHandler.prepareConstructorModel(for: request)
        view.configure(model: constructorModel)
        view.setInnerTridentLoading(.ready)
    }

    /// Whether request resolution failed because the wallet holds a document it can't present — expired or revoked/suspended.
    ///
    /// The SDK removes expired documents before matching (`EudiWallet.prepareServiceDataParameters`) and has no revocation filter, so an expired document fails resolution here while a revoked one reaches `processRequest`.
    /// Gated on the document-resolution failure codes so unrelated failures (transport, etc.) keep their own message.
    private func requestFailedOnUnshareableDocument(_ error: PresentationError?) -> Bool {
        guard let code = error?.code, Constants.unsatisfiableRequestCodes.contains(code) else { return false }
        let now = Date()
        return WalletDependencies.walletController.fetchAllDocuments().contains { credential in
            credential.isExpired(asOf: now) || revocationService.isRevoked(documentId: credential.id)
        }
    }

    private func showWarningMessage(_ message: String) {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
        view.showError(error: message)
    }
    
    // MARK: - Authentication
    private func showAuthBeforeSend(onSuccess: @escaping () -> Void, onCancel: @escaping () -> Void) {
        WalletDependencies.authGate.presentAuthBeforeSend(in: view, onSuccess: onSuccess, onCancel: onCancel)
    }

    // MARK: - Navigation
    private func openCreateWalletModule() {
        WalletDependencies.onboardingLauncher.presentOnboardingFlow(in: view, flowCoordinator: flowCoordinator)
    }

    // MARK: - Handlers
    private func handleAlert(alert: AlertTemplate) {
        WalletDependencies.templatePresenter.handle(alert, in: view) { [weak self] action in
            guard let self = self else { return }
            switch action {
            case .resume:
                self.openCreateWalletModule()
            case .ok:
                if let redirectCallback, let redirectUrl {
                    redirectCallback(redirectUrl)
                } else if let redirectUrl, let url = URL(string: redirectUrl), url.scheme?.lowercased() == "https" {
                    UIApplication.shared.open(url)
                }
                fallthrough
            default:
                self.remoteSessionManager.cancelPresentation()
                self.view.closeModule(animated: true)
            }
        }
    }
}

// MARK: - WalletRemoteSession Delegate
extension WalletRemoteSharingPresenter: WalletRemoteSessionDelegate {
    func didReceiveRequest(_ request: PresentationRequest) {
        processRequest(request)
    }

    func didFinishPresentation(with redirectUrl: String?) {
        self.redirectUrl = redirectUrl
        buttonViewModel?.state.value = .enabled
        handleAlert(alert: Constants.successAlert)
    }
    
    func didReceiveError(_ error: PresentationError?) {
        // A failed verifier reader-auth chain aborts request resolution (no request is ever delivered), so the untrusted-verifier case arrives here as an error, not via the `isTrusted` gate.
        guard error?.code != .readerNotTrusted else {
            handleAlert(alert: Constants.untrustedVerifierAlert)
            return
        }

        // An expired document is filtered out by the SDK before matching, so it fails resolution here rather than reaching `processRequest` — surface the same alert the revoked path shows.
        if requestFailedOnUnshareableDocument(error) {
            handleAlert(alert: Constants.noDocumentsAlert)
            return
        }

        let friendlyDescription = WalletDependencies.walletErrorFormatter.formatError(error)
        handleAlert(alert: Constants.makeErrorAlert(details: friendlyDescription))
    }
}

// MARK: - Constants
private extension WalletRemoteSharingPresenter {
    enum Constants {
        static let sendSelectiveDisclosureAction = "send_selective_disclosure"
        static let backAction = "back"
        static let successIcon = "doneBlackRound"
        static let errorIcon = "attentionBlackRound"

        /// Resolution-failure codes an expired (SDK-filtered) or revoked document can produce — the trigger for showing the "required document is missing" alert instead of a raw claim/credential error.
        static let unsatisfiableRequestCodes: Set<PresentationError.Code> = [
            .claimNotFound,
            .claimSetNotSatisfied,
            .credentialNotFound,
            .credentialSetNotSatisfied,
            .dcqlQueryNotSatisfied,
            .noDocumentsAvailable
        ]
        
        static var successAlert: AlertTemplate = .init(
            type: .middleCenterIconBlackButtonAlert,
            isClosable: false,
            data: AlertTemplateData(
                icon: successIcon,
                title: WalletStringKey.sharingSuccessTitle.localized(),
                description: nil,
                mainButton: AlertButtonModel(
                    title: WalletStringKey.sharingSuccessButton.localized(),
                    icon: nil,
                    action: .ok
                ),
                alternativeButton: nil
            )
        )

        static func makeErrorAlert(details: String? = nil) -> AlertTemplate {
            let description = details ?? WalletStringKey.sharingErrorDescriptionDefault.localized()
            return .init(
                type: .middleCenterIconBlackButtonAlert,
                isClosable: false,
                data: AlertTemplateData(
                    icon: errorIcon,
                    title: WalletStringKey.sharingErrorTitle.localized(),
                    description: description,
                    mainButton: AlertButtonModel(
                        title: WalletStringKey.generalProblemOk.localized(),
                        icon: nil,
                        action: .cancel
                    ),
                    alternativeButton: nil
                )
            )
        }

        static var noDocumentsAlert: AlertTemplate = .init(
            type: .middleCenterIconBlackButtonAlert,
            isClosable: false,
            data: AlertTemplateData(
                icon: errorIcon,
                title: WalletStringKey.sharingNoDocumentsTitle.localized(),
                description: WalletStringKey.sharingNoDocumentsDescription.localized(),
                mainButton: AlertButtonModel(
                    title: WalletStringKey.generalProblemOk.localized(),
                    icon: nil,
                    action: .cancel
                ),
                alternativeButton: nil
            )
        )

        static var untrustedVerifierAlert: AlertTemplate = .init(
            type: .middleCenterIconBlackButtonAlert,
            isClosable: false,
            data: AlertTemplateData(
                icon: errorIcon,
                title: WalletStringKey.sharingUntrustedVerifierTitle.localized(),
                description: WalletStringKey.sharingUntrustedVerifierDescription.localized(),
                mainButton: AlertButtonModel(
                    title: WalletStringKey.sharingUntrustedVerifierButton.localized(),
                    icon: nil,
                    action: .cancel
                ),
                alternativeButton: nil
            )
        )

    }
}
