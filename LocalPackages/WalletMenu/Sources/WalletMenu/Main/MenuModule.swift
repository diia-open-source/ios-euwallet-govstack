//
//  MenuModule.swift
//

import UIKit
import DiiaMVPModule
import DiiaUIComponents
import DiiaCommonServices
import WalletAuthorizationPinCode
import WalletCore
import WalletDomainModels
import WalletTransaction

public final class MenuModule: BaseModule {
    private let view: ConstructorViewController
    private let presenter: MenuPresenter

    public init(
        view: ConstructorViewController,
        viewStateFactory: MenuViewStateFactoryProtocol,
        transactionLogStorage: TransactionLogStorage,
        transactionsViewStateFactory: TransactionsViewStateFactoryProtocol,
        flowProvider: MenuFlowProviding,
        biometryService: BiometryAuthServiceProtocol,
        backgroundImage: UIImage? = nil
    ) {
        self.view = view
        presenter = MenuPresenter(
            view: view,
            viewStateFactory: viewStateFactory,
            transactionLogStorage: transactionLogStorage,
            transactionsViewStateFactory: transactionsViewStateFactory,
            flowProvider: flowProvider,
            backgroundImage: backgroundImage,
            biometryService: biometryService
        )
        view.presenter = presenter
    }

    public func viewController() -> UIViewController {
        return view
    }
}
