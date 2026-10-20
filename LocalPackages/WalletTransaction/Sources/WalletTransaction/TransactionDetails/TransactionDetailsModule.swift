//
//  TransactionDetailsModule.swift
//

import UIKit
import DiiaMVPModule
import DiiaUIComponents
import WalletCore
import WalletDomainModels

final class TransactionDetailsModule: BaseModule {
    private let view: ConstructorViewController
    private let presenter: TransactionDetailsPresenter

    init(
        view: ConstructorViewController,
        entry: TransactionLogEntry,
        documents: [Credential],
        walletController: WalletKitProtocol,
        viewStateFactory: TransactionDetailsViewStateFactoryProtocol,
        documentClaimsMapper: TransactionDetailsDocumentClaimsMapperProtocol
    ) {
        self.view = view
        presenter = TransactionDetailsPresenter(
            view: view,
            entry: entry,
            documents: documents,
            walletController: walletController,
            viewStateFactory: viewStateFactory,
            documentClaimsMapper: documentClaimsMapper
        )
        view.presenter = presenter
    }

    func viewController() -> UIViewController {
        return view
    }
}
