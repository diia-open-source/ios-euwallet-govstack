//
//  WalletProximitySharingModule.swift
//

import UIKit
import DiiaMVPModule
import DiiaCommonTypes
import DiiaUIComponents
import WalletCore
import WalletDomainModels

public final class WalletProximitySharingModule: BaseModule {
    private let view: ConstructorViewController
    private let presenter: WalletProximitySharingPresenter

    public init(
        request: PresentationRequest,
        sessionManager: WalletProximitySessionManaging
    ) {
        view = ConstructorViewController()
        presenter = WalletProximitySharingPresenter(
            request: request,
            sessionManager: sessionManager,
            view: view,
            flowCoordinator: PublicServiceFlowCoordinator(rootView: view)
        )
        view.presenter = presenter
    }

    public func viewController() -> UIViewController {
        return view
    }
}
