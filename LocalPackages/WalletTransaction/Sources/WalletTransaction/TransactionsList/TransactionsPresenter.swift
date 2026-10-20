//
//  TransactionsPresenter.swift
//

import Foundation
import DiiaMVPModule
import DiiaUIComponents
import DiiaCommonServices
import WalletCore
import WalletDomainModels

final class TransactionsPresenter: ConstructorScreenPresenter {
    unowned var view: ConstructorScreenViewProtocol
    private let transactionLogStorage: TransactionLogStorage
    private let viewStateFactory: TransactionsViewStateFactoryProtocol
    private var entries: [TransactionLogEntry] = []

    init(
        view: ConstructorScreenViewProtocol,
        transactionLogStorage: TransactionLogStorage,
        viewStateFactory: TransactionsViewStateFactoryProtocol
    ) {
        self.view = view
        self.transactionLogStorage = transactionLogStorage
        self.viewStateFactory = viewStateFactory
    }

    func configureView() {
        view.setLoadingState(.loading)
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                self.entries = try await transactionLogStorage.fetchAll()
            } catch {
                self.entries = []
                self.showFetchErrorAlert(message: error.localizedDescription)
            }

            self.view.configure(model: self.viewStateFactory.make(entries: self.entries))
            self.view.setLoadingState(.ready)
        }
    }

    func handleEvent(event: ConstructorItemEvent) {
        guard let action = event.actionParameters(),
              let txAction = TransactionsAction(rawValue: action.type)
        else { return }

        switch txAction {
        case .back:
            view.closeModule(animated: true)
        case .selectLog:
            guard let resource = action.resource,
                  let id = Int64(resource),
                  let entry = entries.first(where: { $0.id == id })
            else { return }
            onSelectedEntry(entry)
        }
    }

    // MARK: - Private
    private func onSelectedEntry(_ entry: TransactionLogEntry) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            let documents = (try? await transactionLogStorage.fetchPresentedDocuments(forLogId: entry.id)) ?? []
            view.open(module: TransactionDetailsModule(
                view: ConstructorViewController(),
                entry: entry,
                documents: documents,
                walletController: WalletDependencies.walletController,
                viewStateFactory: TransactionDetailsViewStateFactory(),
                documentClaimsMapper: TransactionDetailsDocumentClaimsMapper()
            ))
        }
    }

    private func showFetchErrorAlert(message: String) {
        let okAction = AlertAction(
            title: WalletStringKey.generalProblemOk.localized(),
            type: .normal,
            callback: {}
        )
        let module = CustomAlertModule(
            title: WalletStringKey.sharingErrorTitle.localized(),
            message: message,
            actions: [okAction]
        )
        view.showChild(module: module)
    }
}
