import UIKit
import WalletAuthorization
import WalletAppStorage
import WalletGallery
import WalletCore
import WalletDomainModels

struct AuthorizationStateHandler: AuthorizationServiceStateHandler {
    
    private let appRouter: AppRouter
    private let storage: StoreHelper

    internal init(appRouter: AppRouter, storage: StoreHelper) {
        self.appRouter = appRouter
        self.storage = storage
    }

    func onLoginDidFinish() {
        // Authenticated session begins: start the two polling services. The
        // deferred-issuance alert remains suppressed until AppRouter installs
        // an `alertHostProvider` once the main tab bar is on screen.
        WalletDependencies.walletLifecycle.startSession()
    }

    func onLogoutDidFinish() {
        Self.wipeAllUserData(storage: storage)
        // Drop any deeplink deferred in the previous session before re-arming, so it can't auto-fire after the new PIN setup. A launch-time deeplink is preserved — only logout clears.
        appRouter.clearDeferredActions()
        appRouter.start()
        UIApplication.shared.applicationIconBadgeNumber = 0
    }

    /// Wipe all per-user state (documents, transaction log, provider caches, UserDefaults/keychain) without navigating.
    /// Shared by logout and the 3-strike path: wipes eagerly, not gated on an alert button, so a force-quit can't preserve the documents.
    static func wipeAllUserData(storage: StoreHelperProtocol) {
        DocumentsProcessor.instance.cleanAllProvidersStorage()

        Task {
            try? await WalletDependencies.walletController.clearAllDocuments()
            try? await AppConfigurator.transactionLogController.transactionLogStorage.deleteAll()
        }

        // Single end-of-session entry point: stops both polling services, clears
        // the revocation cache and the deferred-issuance alert gate.
        WalletDependencies.walletLifecycle.endSession()

        storage.clearAllData()
    }
}
