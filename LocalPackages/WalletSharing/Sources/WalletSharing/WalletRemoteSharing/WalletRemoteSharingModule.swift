//
//  WalletRemoteSharingModule.swift
//

import UIKit
import DiiaMVPModule
import DiiaCommonTypes
import DiiaUIComponents

public final class WalletRemoteSharingModule: BaseModule {
    private let view: ConstructorViewController
    private let presenter: WalletRemoteSharingPresenter

    public init(link: String, redirectCallback: ((String) -> Void)? = nil) {
        view = ConstructorViewController()
        presenter = WalletRemoteSharingPresenter(
            view: view,
            link: link,
            redirectCallback: redirectCallback
        )
        view.presenter = presenter
    }

    public func viewController() -> UIViewController {
        return view
    }
}
