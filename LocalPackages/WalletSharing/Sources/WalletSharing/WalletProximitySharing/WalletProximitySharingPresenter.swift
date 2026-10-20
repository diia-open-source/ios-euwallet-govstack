//
//  WalletProximitySharingPresenter.swift
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

final class WalletProximitySharingPresenter: ConstructorScreenPresenter {
    
    // MARK: - Properties
    unowned var view: ConstructorScreenViewProtocol
    
    private let flowCoordinator: FlowCoordinatorProtocol
    private let proximitySessionManager: WalletProximitySessionManaging
    private let sharingDataHandler = WalletSharingDataHandler()
    private let revocationService: DocumentRevocationService

    private let request: PresentationRequest
    private var buttonViewModel: DSLoadingButtonViewModel?

    // MARK: - Init
    init(
        request: PresentationRequest,
        sessionManager: WalletProximitySessionManaging,
        view: ConstructorScreenViewProtocol,
        flowCoordinator: FlowCoordinatorProtocol,
        revocationService: DocumentRevocationService = WalletDependencies.walletLifecycle.revocationService
    ) {
        self.request = request
        self.proximitySessionManager = sessionManager
        self.view = view
        self.flowCoordinator = flowCoordinator
        self.revocationService = revocationService
        self.proximitySessionManager.delegate = self
    }

    deinit {
        proximitySessionManager.cancelPresentation()
    }

    // MARK: - Public Methods
    func configureView() {
        view.setInnerTridentLoading(.loading)

        // Pre-load issuer metadata for user-friendly error messages
        WalletDependencies.walletErrorFormatter.preloadMetadata()

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

        // Check for revoked documents
        let revokedDocIds = request.items.filter { item in
            revocationService.isRevoked(documentId: item.id)
        }.map { $0.id }

        if !revokedDocIds.isEmpty {
            handleAlert(alert: Constants.noDocumentsAlert)
            view.setInnerTridentLoading(.ready)
            return
        }

        processRequest()
        
        view.setInnerTridentLoading(.ready)
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
    private func actionTapped(action: DSActionParameter) {
        switch action.type {
        case Constants.sendSelectiveDisclosureAction:
            buttonViewModel?.state.value = .loading
            let inputData = view.getInputData()
            let selectedItems = sharingDataHandler.transformAnyCodableToRequest(input: inputData)
            if selectedItems.isEmpty {
                handleAlert(alert: Constants.makeErrorAlert())
                return
            }
            showAuthBeforeSend { [weak self] in
                self?.proximitySessionManager.sendResponse(disclosedItems: selectedItems)
            } onCancel: { [weak self] in
                self?.buttonViewModel?.state.value = .enabled
            }
        case Constants.backAction:
            proximitySessionManager.cancelPresentation()
            view.closeModule(animated: true)
        default:
            break
        }
    }

    private func processRequest() {
        let constructorModel = sharingDataHandler.prepareConstructorModel(for: request)
        view.configure(model: constructorModel)
        view.setInnerTridentLoading(.ready)
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
            default:
                self.proximitySessionManager.cancelPresentation()
                self.view.closeModule(animated: true)
            }
        }
    }
}

// MARK: - WalletProximitySessionDelegate
extension WalletProximitySharingPresenter: WalletProximitySessionDelegate {
    func didFinishPresentation() {
        buttonViewModel?.state.value = .enabled
        handleAlert(alert: Constants.successAlert)
    }

    func didReceiveError(_ error: PresentationError?, kind: WalletProximityErrorKind?) {
        switch kind {
        case .accessRequired:
            handleAlert(alert: Constants.bluetoothAccessRequiredAlert)
        case .turnedOff:
            handleAlert(alert: Constants.bluetoothTurnOnAlert)
        case .connectionLost:
            handleAlert(alert: Constants.connectionLostAlert)
        case .none:
            // A failed verifier reader-auth chain aborts request resolution (no request is ever delivered), so the untrusted-verifier case arrives here as an error, not via the `isTrusted` gate.
            guard error?.code != .readerNotTrusted else {
                handleAlert(alert: Constants.untrustedVerifierAlert)
                return
            }
            let friendlyDescription = WalletDependencies.walletErrorFormatter.formatError(error)
            handleAlert(alert: Constants.makeErrorAlert(details: friendlyDescription))
        }
    }
}

// MARK: - Constants
private extension WalletProximitySharingPresenter {
    enum Constants {
        static let sendSelectiveDisclosureAction = "send_selective_disclosure"
        static let backAction = "back"
        static let successIcon = "doneBlackRound"
        static let errorIcon = "attentionBlackRound"
        
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

        static var bluetoothAccessRequiredAlert: AlertTemplate = .init(
            type: .middleCenterIconBlackButtonAlert,
            isClosable: false,
            data: AlertTemplateData(
                icon: errorIcon,
                title: WalletStringKey.eudiQrBluetoothAccessRequiredTitle.localized(),
                description: WalletStringKey.eudiQrBluetoothAccessRequiredDescription.localized(),
                mainButton: AlertButtonModel(
                    title: WalletStringKey.generalProblemOk.localized(),
                    icon: nil,
                    action: .cancel
                ),
                alternativeButton: nil
            )
        )

        static var bluetoothTurnOnAlert: AlertTemplate = .init(
            type: .middleCenterIconBlackButtonAlert,
            isClosable: false,
            data: AlertTemplateData(
                icon: errorIcon,
                title: WalletStringKey.eudiQrBluetoothTurnOnTitle.localized(),
                description: WalletStringKey.eudiQrBluetoothTurnOnDescription.localized(),
                mainButton: AlertButtonModel(
                    title: WalletStringKey.generalProblemOk.localized(),
                    icon: nil,
                    action: .cancel
                ),
                alternativeButton: nil
            )
        )

        static var connectionLostAlert: AlertTemplate = .init(
            type: .middleCenterIconBlackButtonAlert,
            isClosable: false,
            data: AlertTemplateData(
                icon: errorIcon,
                title: WalletStringKey.sharingConnectionLostTitle.localized(),
                description: WalletStringKey.sharingConnectionLostDescription.localized(),
                mainButton: AlertButtonModel(
                    title: WalletStringKey.generalProblemOk.localized(),
                    icon: nil,
                    action: .cancel
                ),
                alternativeButton: nil
            )
        )

    }
}
