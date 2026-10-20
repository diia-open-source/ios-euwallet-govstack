import UIKit
import DiiaMVPModule

/// Module for prompting user to enable biometry after PIN creation
public final class BiometrySetupModule: BaseModule {
    private let view: BiometrySetupViewController
    private let presenter: BiometrySetupPresenter

    public init(
        biometryService: BiometryAuthServiceProtocol,
        onComplete: @escaping () -> Void
    ) {
        view = BiometrySetupViewController()
        presenter = BiometrySetupPresenter(
            view: view,
            biometryService: biometryService,
            onComplete: onComplete
        )
        view.presenter = presenter
    }

    public func viewController() -> UIViewController {
        return view
    }
}
