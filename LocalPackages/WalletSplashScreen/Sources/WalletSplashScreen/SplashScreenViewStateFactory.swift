import DiiaUIComponents
import WalletCore
import WalletDomainModels

protocol SplashScreenViewStateFactoryProtocol {
    func make() -> DSConstructorModel
}

struct SplashScreenViewStateFactory: SplashScreenViewStateFactoryProtocol {
    func make() -> DSConstructorModel {
        DSConstructorModel(
            centeredBody: [
                .component(key: SplashTitleBuilder.key, model: SplashTitleModel(
                    label: WalletStringKey.splashScreenTitle.localized(),
                    componentId: "splash_screen_title"
                ))
            ],
            bottomGroup: [
                .component(key: SplashLogosBuilder.key, model: SplashLogosModel(
                    componentId: "splash_screen_logos"
                ))
            ]
        )
    }
}
