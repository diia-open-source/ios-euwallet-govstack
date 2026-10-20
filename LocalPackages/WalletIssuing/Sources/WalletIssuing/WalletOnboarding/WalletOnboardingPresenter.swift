//
//  WalletOnboardingPresenter.swift
//

import UIKit
import DiiaMVPModule
import DiiaCommonTypes
import DiiaUIComponents
import DiiaCommonServices
import WalletDocumentsCore
import WalletDocumentsCommonTypes
import WalletCore
import WalletDomainModels
import WalletContextMenu

final class WalletOnboardingPresenter: ConstructorScreenPresenter {

    // MARK: - Properties
    unowned var view: ConstructorScreenViewProtocol

    private var contextMenuProvider: ContextMenuProviderProtocol
    private let walletController: WalletKitProtocol
    private let flowCoordinator: FlowCoordinatorProtocol

    private let documentType: AvailableDocumentType
    private let backgroundImage: UIImage?
    private var buttonViewModel: DSLoadingButtonViewModel?

    // MARK: - Init
    init(
        documentType: AvailableDocumentType,
        backgroundImage: UIImage?,
        view: ConstructorScreenViewProtocol,
        flowCoordinator: FlowCoordinatorProtocol,
        contextMenuProvider: ContextMenuProviderProtocol
    ) {
        self.documentType = documentType
        self.backgroundImage = backgroundImage
        self.view = view
        self.flowCoordinator = flowCoordinator
        self.contextMenuProvider = contextMenuProvider

        self.walletController = WalletDependencies.walletController
    }

    // MARK: - Public Methods
    func configureView() {
        view.setupBackground(.image(backgroundImage ?? UIImage()))
        activateEudiWallet()
    }

    func openContextMenu() {
        contextMenuProvider.openContextMenu(in: view)
    }

    func handleEvent(event: ConstructorItemEvent) {
        switch event {
        case .inputChanged:
            view.inputFieldsWasUpdated()
        case .buttonAction(let parameters, let viewModel):
            actionTapped(action: parameters, viewModel: viewModel)
        default:
            guard let action = event.actionParameters() else { return }
            actionTapped(action: action)
        }
    }

    // MARK: - Private Methods
    private func actionTapped(action: DSActionParameter, viewModel: DSLoadingButtonViewModel? = nil) {
        self.buttonViewModel = viewModel
        switch action.type {
        case Constants.activateEudiWallet:
            activateEudiWallet()
        case Constants.backAction:
            view.closeModule(animated: true)
        default:
            break
        }
    }

    private func activateEudiWallet() {
        view.showProgress()
        Task { [weak self] in
            guard let self else { return }

            do {
//                if self.documentType == .pid {
//                    try await self.walletController.clearAllDocuments()
//                }
                let result = try await self.walletController.issueDocument(
                    issuerId: self.documentType.issuerId,
                    identifier: self.documentType.identifier
                )
                try? await self.walletController.loadDocuments()

                await MainActor.run {
                    WalletDependencies.documentsRefresher.walletDidRefreshDocuments()
                    self.view.hideProgress()
                    // Onboarding can hand back a deferred result (e.g. `_deferred`-suffixed
                    // credential configurations on the EUDI dev issuer). Without this branch,
                    // the success alert would fire and nothing would kick the deferred poller,
                    // leaving the doc stuck until the next app foreground.
                    if result.isDeferred {
                        WalletDependencies.walletLifecycle.deferredCoordinator.kick()
                        self.handleAlert(alert: Constants.deferredPendingAlert)
                    } else {
                        self.handleAlert(alert: Constants.successAlert)
                    }
                }
            } catch let WalletCredentialIssuanceError.template(alertTemplate) {
                await MainActor.run {
                    self.view.hideProgress()
                    self.handleAlert(alert: alertTemplate)
                }
            } catch let error as NSError
                where error.domain == "com.apple.AuthenticationServices.WebAuthenticationSession"
                   && error.code == 1 { // ASWebAuthenticationSessionError.canceledLogin
                await MainActor.run {
                    self.view.hideProgress()
                    self.handleAlert(alert: Constants.cancelErrorAlert)
                }
            } catch {
                await MainActor.run {
                    self.view.hideProgress()
                    self.handleAlert(alert: Constants.creationErrorAlert)
                }
            }
        }
    }
    
    // MARK: - Handlers
    private func handleAlert(alert: AlertTemplate) {
        WalletDependencies.templatePresenter.handle(alert, in: view) { [weak self] action in
            guard let self = self else { return }
            switch action {
            case .ok:
                self.flowCoordinator.restartFlow()
                self.view.closeModule(animated: true)
            default:
                self.view.closeModule(animated: true)
            }
        }
    }
}

// MARK: - Constants
private extension WalletOnboardingPresenter {
    enum Constants {
        static let activateEudiWallet = "activate_document"
        static let backAction = "back"
        
        static var successAlert: AlertTemplate {
            .init(
                type: .middleCenterIconBlackButtonAlert,
                isClosable: false,
                data: AlertTemplateData(
                    icon: .doneBlackRound,
                    title: WalletStringKey.issuanceSuccessTitle.localized(),
                    description: WalletStringKey.issuanceSuccessDescription.localized(),
                    mainButton: AlertButtonModel(
                        title: WalletStringKey.issuanceSuccessButton.localized(),
                        icon: nil,
                        action: .ok),
                    alternativeButton: nil)
            )
        }

        static var deferredPendingAlert: AlertTemplate {
            .init(
                type: .middleCenterIconBlackButtonAlert,
                isClosable: false,
                data: AlertTemplateData(
                    icon: .doneBlackRound,
                    title: WalletStringKey.deferredIssuancePendingTitle.localized(),
                    description: WalletStringKey.deferredIssuancePendingDescription.localized(),
                    mainButton: AlertButtonModel(
                        title: WalletStringKey.issuanceSuccessButton.localized(),
                        icon: nil,
                        action: .ok),
                    alternativeButton: nil)
            )
        }

        static var cancelErrorAlert: AlertTemplate {
            .init(
                type: .middleCenterIconBlackButtonAlert,
                isClosable: false,
                data: AlertTemplateData(
                    icon: .attentionBlackRound,
                    title: WalletStringKey.issuanceGenericErrorTitle.localized(),
                    description: WalletStringKey.sharingErrorDescriptionDefault.localized(),
                    mainButton: AlertButtonModel(
                        title: WalletStringKey.generalCancel.localized(),
                        icon: nil,
                        action: .close),
                    alternativeButton: nil)
            )
        }

        static var creationErrorAlert: AlertTemplate {
            .init(
                type: .middleCenterIconBlackButtonAlert,
                isClosable: false,
                data: AlertTemplateData(
                    icon: .attentionBlackRound,
                    title: WalletStringKey.issuanceErrorTitle.localized(),
                    description: WalletStringKey.issuanceErrorDescription.localized(),
                    mainButton: AlertButtonModel(
                        title: WalletStringKey.generalProblemOk.localized(),
                        icon: nil,
                        action: .close),
                    alternativeButton: nil)
            )
        }
    }
}
