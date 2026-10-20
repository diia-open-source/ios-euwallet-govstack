
import Foundation
import UIKit
import DiiaMVPModule
import DiiaUIComponents
import DiiaCommonTypes
import WalletDocumentsCommonTypes

final class DocumentActionSheetModule: BaseModule {
    private let view: DocumentActionSheetViewController
    
    init(actions: [[Action]]) {
        view = DocumentActionSheetViewController()
        view.actions = actions
    }
    
    public func viewController() -> UIViewController {
        let vc = ChildContainerViewController()
        vc.childSubview = view
        vc.presentationStyle = .actionSheet
        return vc
    }
}
