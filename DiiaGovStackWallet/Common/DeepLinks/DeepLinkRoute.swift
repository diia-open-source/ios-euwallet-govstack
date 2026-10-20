import Foundation
import DiiaCommonTypes

protocol DeepLinkRouteBuilder {
    func canCreateRoute(with urlString: String) -> Bool
    func needAuth() -> Bool
    func create(with urlString: String) -> RouterProtocol?
}
