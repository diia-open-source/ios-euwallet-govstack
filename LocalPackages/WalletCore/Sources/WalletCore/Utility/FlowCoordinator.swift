import UIKit
import WalletDomainModels
import DiiaMVPModule
import DiiaCommonTypes

public class PublicServiceFlowCoordinator: FlowCoordinatorProtocol {
    public weak var rootView: BaseView?
    public var restartCallback: Callback?
    public var successCallback: ((Bool) -> Void)?

    public init(
        rootView: BaseView?,
        restartCallback: Callback? = nil,
        successCallback: ((Bool) -> Void)? = nil
    ) {
        self.rootView = rootView
        self.restartCallback = restartCallback
        self.successCallback = successCallback
    }

    public func restartFlow() {
        restartCallback?()
        guard let rootView = rootView else {
            return
        }
        rootView.closeToView(view: rootView, animated: true)
    }

    public func flowWasFinishedWithSuccess(success: Bool) {
        guard let callback = successCallback else {
            restartFlow()
            return
        }
        callback(success)
    }

    public func restartFlow(with modules: [BaseModule]) {
        guard let vc = rootView as? UIViewController else {
            return
        }
        vc.navigationController?.view.endEditing(true)
        vc.navigationController?.replaceViewControllers(
            with: modules.map { $0.viewController() },
            after: vc.topNonNavigationParent())
        restartCallback?()
    }

    public func closeFlow() {
        guard let vc = rootView as? UIViewController else {
            return
        }
        vc.navigationController?.replaceViewControllers(
            with: [],
            after: vc.topNonNavigationParent(),
            includingReference: true)
    }
}
