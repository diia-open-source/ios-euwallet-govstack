//
//  DocumentDetailsCommonModule.swift
//

import UIKit
import DiiaMVPModule
import DiiaCommonTypes
import DiiaUIComponents
import WalletDocumentsCommonTypes

public final class DocumentDetailsCommonModule: BaseModule {

    let view: DocumentDetailsCommonViewController
    let presenter: DocumentDetailsCommonPresenter

    public init(
        with viewModel: DocumentDetailsCommonViewModel,
        insuranceTicker: DSTickerAtom? = nil,
        viewStateFactory: DocumentDetailsCommonViewStateFactoryProtocol,
        screenBrightnessService: ScreenBrightnessServiceProtocol? = DocumentsCommonConfiguration.shared.screenBrightnessService
    ) {
        view = DocumentDetailsCommonViewController()
        presenter = DocumentDetailsCommonPresenter(
            view: view,
            viewModel: viewModel,
            insuranceTicker: insuranceTicker,
            viewStateFactory: viewStateFactory,
            screenBrightnessService: screenBrightnessService
        )
        view.presenter = presenter
    }

    public func viewController() -> UIViewController {
        return PresentedController(viewController: view)
    }
}
