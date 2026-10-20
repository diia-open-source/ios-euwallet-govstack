
import Foundation
import DiiaMVPModule
import DiiaCommonTypes

public struct AuthorizationNetworkContext {
    public let host: String
    public let headers: [String: String]?

    public init(host: String, headers: [String: String]?) {
        self.host = host
        self.headers = headers
    }
}

public struct AuthorizationContext {
    let network: AuthorizationNetworkContext
    let storage: AuthorizationStorageProtocol
    let serviceAuthSuccessModule: BaseModule?
    let authStateHandler: AuthorizationServiceStateHandler

    public init(
        network: AuthorizationNetworkContext,
        storage: AuthorizationStorageProtocol,
        serviceAuthSuccessModule: BaseModule?,
        authStateHandler: AuthorizationServiceStateHandler,
    ) {
        self.network = network
        self.storage = storage
        self.serviceAuthSuccessModule = serviceAuthSuccessModule
        self.authStateHandler = authStateHandler
    }
}
