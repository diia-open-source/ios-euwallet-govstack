
import UIKit
import DiiaMVPModule
import DiiaUIComponents
  
public protocol EnterPinCodeDelegate {
    func onForgotPincode(in view: BaseView)
    func didAllAttemptsExhausted(in view: BaseView)
    func checkPincode(_ pincode: [Int]) -> Bool
    func didCorrectPincodeEntered(pincode: String)
}

public final class EnterPinCodeModule: BaseModule {
    private let view: EnterPinCodeViewController
    private let presenter: EnterPinCodeAction
    
    public init(context: EnterPinCodeModuleContext, viewModel: EnterPinCodeViewModel) {
        view = EnterPinCodeViewController.storyboardInstantiate(bundle: Bundle.module)
        presenter = EnterPinCodeAuthPresenter(context: context, view: view, viewModel: viewModel)
        view.presenter = presenter
    }

    public func viewController() -> UIViewController {
        return view
    }

    public func configureAdditionalButton(image: UIImage?, accessibilityLabel: String? = nil, accessibilityHint: String? = nil, action: @escaping () -> Void) {
        view.configureAdditionalButton(image: image, accessibilityLabel: accessibilityLabel, accessibilityHint: accessibilityHint, action: action)
    }
}

// MARK: - EnterPinCodeInContainerModule
public final class EnterPinCodeInContainerModule: BaseModule {
    private let view: EnterPinCodeViewController
    private let presenter: EnterPinCodeAction
    private let container: ChildContainerViewController
    
    public init(
        context: EnterPinCodeModuleContext,
        viewModel: EnterPinCodeViewModel
    ) {
        view = EnterPinCodeViewController.storyboardInstantiate(bundle: Bundle.module)
        presenter = EnterPinCodeAuthPresenter(context: context, view: view, viewModel: viewModel)
        view.presenter = presenter
        
        let childContainer = ChildContainerViewController()
        childContainer.childSubview = view
        childContainer.presentationStyle = .fullscreen
        container = childContainer
    }

    public func viewController() -> UIViewController {
        return container
    }
}
