import UIKit
import DiiaMVPModule
import DiiaCommonTypes
import DiiaUIComponents

public final class SplashScreenModule: BaseModule {
    private let view: ConstructorViewController
    private let presenter: SplashScreenPresenter

    public init(
        backgroundImage: UIImage? = nil,
        logosImage: UIImage? = nil,
        onFinish: @escaping Callback
    ) {
        view = ConstructorViewController()
        let fabric = DSViewFabric()
        fabric.setBuilder(SplashTitleBuilder())
        fabric.setBuilder(SplashLogosBuilder(logosImage: logosImage))
        view.setFabric(fabric)
        presenter = SplashScreenPresenter(
            view: view,
            backgroundImage: backgroundImage,
            onFinish: onFinish,
            viewStateFactory: SplashScreenViewStateFactory()
        )
        view.presenter = presenter
    }

    public func viewController() -> UIViewController {
        return view
    }
}
