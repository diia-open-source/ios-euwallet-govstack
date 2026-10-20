//
//  MenuPresenter.swift
//

import UIKit
import DiiaMVPModule
import DiiaUIComponents
import DiiaCommonServices
import WalletAuthorizationPinCode
import WalletCore
import WalletDomainModels
import WalletTransaction

final class MenuPresenter: ConstructorScreenPresenter {
    unowned var view: ConstructorScreenViewProtocol
    private let viewStateFactory: MenuViewStateFactoryProtocol
    private let transactionLogStorage: TransactionLogStorage
    private let transactionsViewStateFactory: TransactionsViewStateFactoryProtocol
    private let flowProvider: MenuFlowProviding
    private let backgroundImage: UIImage?
    private let biometryService: BiometryAuthServiceProtocol

    init(
        view: ConstructorScreenViewProtocol,
        viewStateFactory: MenuViewStateFactoryProtocol,
        transactionLogStorage: TransactionLogStorage,
        transactionsViewStateFactory: TransactionsViewStateFactoryProtocol,
        flowProvider: MenuFlowProviding,
        backgroundImage: UIImage?,
        biometryService: BiometryAuthServiceProtocol
    ) {
        self.view = view
        self.viewStateFactory = viewStateFactory
        self.transactionLogStorage = transactionLogStorage
        self.transactionsViewStateFactory = transactionsViewStateFactory
        self.flowProvider = flowProvider
        self.backgroundImage = backgroundImage
        self.biometryService = biometryService
    }

    func configureView() {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        if let backgroundImage {
            view.setupBackground(.image(backgroundImage))
        }
        view.configure(model: viewStateFactory.make(version: version))
    }

    func handleEvent(event: ConstructorItemEvent) {
        guard let action = event.actionParameters(),
              let menuAction = MenuScreenAction(rawValue: action.type)
        else { return }

        switch menuAction {
        case .back:
            view.closeModule(animated: true)
        case .openTransactions:
            openTransactions()
        case .openScanQR:
            flowProvider.presentQRScanner(in: view)
        case .openSettings:
            view.open(module: SettingsModule(flowProvider: flowProvider, biometryService: biometryService))
        case .logout:
            showLogoutConfirmation()
        }
    }

    // MARK: - Private
    private func openTransactions() {
        view.open(module: TransactionsModule(
            transactionLogStorage: transactionLogStorage,
            viewStateFactory: transactionsViewStateFactory
        ))
    }

    private func showLogoutConfirmation() {
        let logoutAction = AlertAction(
            title: WalletStringKey.menuLogout.localized(),
            type: .destructive,
            callback: { [weak self] in
                self?.flowProvider.performLogout()
            }
        )
        let cancelAction = AlertAction(
            title: WalletStringKey.menuLogoutCancel.localized(),
            type: .normal,
            callback: {}
        )
        let module = CustomAlertModule(
            title: WalletStringKey.menuLogoutTitle.localized(),
            message: WalletStringKey.menuLogoutMessage.localized(),
            actions: [logoutAction, cancelAction]
        )
        view.showChild(module: module)
    }
}
