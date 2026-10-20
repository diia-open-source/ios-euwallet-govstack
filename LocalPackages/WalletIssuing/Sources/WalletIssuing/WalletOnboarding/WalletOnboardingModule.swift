//
//  WalletOnboardingModule.swift
//

import UIKit
import DiiaMVPModule
import DiiaCommonTypes
import DiiaUIComponents
import WalletDocumentsCore
import WalletCore
import WalletDomainModels
import WalletContextMenu

public final class WalletOnboardingModule: BaseModule {
    private let view: ConstructorViewController
    private let presenter: WalletOnboardingPresenter

    public init(
        documentType: AvailableDocumentType,
        backgroundImage: UIImage? = nil,
        flowCoordinator: FlowCoordinatorProtocol? = nil,
        restartCallback: Callback? = nil,
        contextMenuProvider: ContextMenuProviderProtocol = BaseContextMenuProvider()
    ) {
        view = ConstructorViewController()
        let resolvedCoordinator = flowCoordinator ?? PublicServiceFlowCoordinator(
            rootView: view,
            restartCallback: restartCallback
        )
        presenter = WalletOnboardingPresenter(
            documentType: documentType,
            backgroundImage: backgroundImage,
            view: view,
            flowCoordinator: resolvedCoordinator,
            contextMenuProvider: contextMenuProvider
        )
        view.presenter = presenter
    }

    public func viewController() -> UIViewController {
        return view
    }
}
