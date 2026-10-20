import Foundation
import DiiaCommonTypes
import DiiaCommonServices
import WalletCore
import WalletDomainModels

class DeepLinkManager {
    var appRouter: AppRouter?

    @discardableResult
    func parse(url: URL) -> Bool {
        guard
            let urlString = url
                .absoluteString
                .removingPercentEncoding?
                .addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed),
            let newUrl = URL(string: urlString),
            let components = URLComponents(url: newUrl, resolvingAgainstBaseURL: true)
        else {
            return false
        }

        guard let routerBuilder = DeeplinksRoutersList.userRouters.first(where: { $0.canCreateRoute(with: urlString) }),
              let deeplinkRouter = routerBuilder.create(with: urlString)
        else {
            return false
        }

        route(with: deeplinkRouter, needPincode: routerBuilder.needAuth())

        return true
    }

    private func route(with router: RouterProtocol, needPincode: Bool) {
        appRouter?.performOrDefer(
            action: { view in
                guard let view = view else { return }
                router.route(in: view)
            },
            needPincode: needPincode
        )
    }
}

extension DeepLinkManager: DeepLinkManagerProtocol { }
