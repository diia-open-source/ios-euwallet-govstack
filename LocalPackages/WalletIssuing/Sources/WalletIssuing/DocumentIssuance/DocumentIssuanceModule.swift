//
//  DocumentIssuanceModule.swift
//

import UIKit
import DiiaMVPModule
import DiiaCommonTypes
import DiiaUIComponents
import WalletCore
import WalletDomainModels

public final class DocumentIssuanceModule: BaseModule {
    private let view: ConstructorViewController
    private let presenter: DocumentIssuancePresenter

    public init(
        offerUri: String,
        viewStateFactory: DocumentIssuanceViewStateFactoryProtocol
    ) {
        view = ConstructorViewController()
        let fabric = DSViewFabric()
        fabric.setBuilder(IssuanceDescriptionCardBuilder())
        view.setFabric(fabric)
        presenter = DocumentIssuancePresenter(
            view: view,
            offerUri: offerUri,
            viewStateFactory: viewStateFactory
        )
        view.presenter = presenter
    }

    public func viewController() -> UIViewController {
        return view
    }
}
