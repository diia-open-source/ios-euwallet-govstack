//
//  DocumentsQRModule.swift
//

import UIKit
import DiiaMVPModule
import DiiaCommonTypes
import DiiaUIComponents

public final class DocumentsQRModule: BaseModule {
    private let view: DocumentsQRViewController
    private let presenter: DocumentsQRPresenter

    public init(closeButtonImage: UIImage? = nil, onClose: Callback? = nil) {
        view = DocumentsQRViewController(closeButtonImage: closeButtonImage)
        presenter = DocumentsQRPresenter(view: view, onClose: onClose)
        view.presenter = presenter
    }

    public func viewController() -> UIViewController {
        let childContainer = ChildContainerViewController()
        childContainer.childSubview = view
        childContainer.presentationStyle = .presentation
        childContainer.isClosingAlowed = false
        return childContainer
    }
}
