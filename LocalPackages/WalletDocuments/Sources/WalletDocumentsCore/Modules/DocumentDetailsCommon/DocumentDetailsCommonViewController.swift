//
//  DocumentDetailsCommonViewController.swift
//

import UIKit
import DiiaUIComponents

public final class DocumentDetailsCommonViewController: ConstructorModalViewController {

    public override init() {
        super.init()
        // Restore default modal presentation so PresentedController shows its top drag
        // handle. The base class sets `.custom`, which suppresses it.
        modalPresentationStyle = .automatic
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func didLoadConstructorView() {
        if let modalView = view as? ConstructorModalView {
            modalView.bodyScrollView.bottomSeparatorType = .none
        }
    }
}
