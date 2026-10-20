import UIKit
import DiiaMVPModule
import DiiaCommonTypes
import DiiaUIComponents

final class SplashScreenPresenter: ConstructorScreenPresenter {
    unowned var view: ConstructorScreenViewProtocol

    private let backgroundImage: UIImage?
    private let onFinish: Callback
    private let viewStateFactory: SplashScreenViewStateFactoryProtocol

    init(
        view: ConstructorScreenViewProtocol,
        backgroundImage: UIImage?,
        onFinish: @escaping Callback,
        viewStateFactory: SplashScreenViewStateFactoryProtocol
    ) {
        self.view = view
        self.backgroundImage = backgroundImage
        self.onFinish = onFinish
        self.viewStateFactory = viewStateFactory
    }

    func configureView() {
        if let backgroundImage {
            view.setupBackground(.image(backgroundImage))
        } else {
            view.setupBackground(.color(.white))
        }
        view.configure(model: viewStateFactory.make())
        onMainQueueAfter(time: LocalConstants.animationDuration) { [onFinish] in
            onFinish()
        }
    }

    func handleEvent(event: ConstructorItemEvent) {
    }
}

private extension SplashScreenPresenter {
    enum LocalConstants {
        static let animationDuration: Double = 1
    }
}
