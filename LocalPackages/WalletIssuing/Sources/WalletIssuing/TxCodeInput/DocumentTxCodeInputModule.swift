//
//  DocumentTxCodeInputModule.swift
//

import UIKit
import DiiaMVPModule
import WalletDomainModels

final class DocumentTxCodeInputModule: BaseModule {
    private let view: DocumentTxCodeInputView
    private let presenter: DocumentTxCodeInputPresenter

    init(txCodeSpec: TxCodeSpec?, onSubmit: @escaping (String) -> Void, onClose: @escaping () -> Void) {
        self.view = DocumentTxCodeInputView()
        self.presenter = DocumentTxCodeInputPresenter(
            view: view,
            txCodeSpec: txCodeSpec,
            onSubmit: onSubmit,
            onClose: onClose
        )
        self.view.presenter = presenter
    }
    
    func viewController() -> UIViewController {
        view.modalPresentationStyle = .overFullScreen
        view.modalTransitionStyle = .crossDissolve
        return view
    }
}
