//
//  TransactionsModule.swift
//

import UIKit
import DiiaMVPModule
import DiiaUIComponents
import WalletCore
import WalletDomainModels

public final class TransactionsModule: BaseModule {
    private let view: ConstructorViewController
    private let presenter: TransactionsPresenter

    public init(
        transactionLogStorage: TransactionLogStorage,
        viewStateFactory: TransactionsViewStateFactoryProtocol
    ) {
        view = ConstructorViewController()
        presenter = TransactionsPresenter(
            view: view,
            transactionLogStorage: transactionLogStorage,
            viewStateFactory: viewStateFactory
        )
        view.presenter = presenter
    }

    public func viewController() -> UIViewController {
        return view
    }
}
