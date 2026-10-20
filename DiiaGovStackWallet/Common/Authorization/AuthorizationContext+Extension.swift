import UIKit
import WalletAuthorization
import WalletAppStorage

extension AuthorizationContext {
    static func create() -> AuthorizationContext {
        .init(network: .create(),
              storage: AuthorizationStorage(storage: StoreHelper.instance),
              serviceAuthSuccessModule: nil,
              authStateHandler: AuthorizationStateHandler(appRouter: AppRouter.instance, storage: StoreHelper.instance))
    }
}

extension AuthorizationNetworkContext {
    static func create() -> AuthorizationNetworkContext {
        // The local-only auth surface (pincode + biometry) never reaches the network host,
        // so the wallet ships without one configured. Wire a real host here if a remote
        // auth endpoint is added later.
        .init(
            host: "",
            headers: nil
        )
    }
}
