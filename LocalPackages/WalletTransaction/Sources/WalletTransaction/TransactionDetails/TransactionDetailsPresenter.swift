//
//  TransactionDetailsPresenter.swift
//

import Foundation
import DiiaMVPModule
import DiiaUIComponents
import WalletCore
import WalletDomainModels

final class TransactionDetailsPresenter: ConstructorScreenPresenter {
    unowned var view: ConstructorScreenViewProtocol
    private let entry: TransactionLogEntry
    private let documents: [Credential]
    private let walletController: WalletKitProtocol
    private let viewStateFactory: TransactionDetailsViewStateFactoryProtocol
    private let documentClaimsMapper: TransactionDetailsDocumentClaimsMapperProtocol

    init(
        view: ConstructorScreenViewProtocol,
        entry: TransactionLogEntry,
        documents: [Credential],
        walletController: WalletKitProtocol,
        viewStateFactory: TransactionDetailsViewStateFactoryProtocol,
        documentClaimsMapper: TransactionDetailsDocumentClaimsMapperProtocol
    ) {
        self.view = view
        self.entry = entry
        self.documents = documents
        self.walletController = walletController
        self.viewStateFactory = viewStateFactory
        self.documentClaimsMapper = documentClaimsMapper
    }

    func configureView() {
        var resolvedDocuments = documents
        switch entry.kind {
        case .issuance(_, let documentId):
            // Issuance entries only persist the document id; fetch the live credential
            // here. Presentation entries already arrive with `documents` populated from
            // the transaction log, and signing/deletion don't render a document body.
            if resolvedDocuments.isEmpty,
               let documentId,
               let document = walletController.fetchDocument(with: documentId) {
                resolvedDocuments = [document]
            }
        case .presentation, .signing, .deletion:
            break
        }
        let model = viewStateFactory.make(
            entry: entry,
            documents: documentClaimsMapper.map(resolvedDocuments)
        )
        view.configure(model: model)
    }

    func handleEvent(event: ConstructorItemEvent) {
        guard let action = event.actionParameters(),
              let detailsAction = TransactionDetailsAction(rawValue: action.type)
        else { return }

        switch detailsAction {
        case .back:
            view.closeModule(animated: true)
        }
    }
}
