import UIKit
import DiiaMVPModule
import DiiaCommonTypes
import DiiaCommonServices
import DiiaUIComponents
import WalletDocumentsCommonTypes
import WalletAppStorage
import WalletGallery
import WalletIssuing
import WalletSharing
import WalletCore
import WalletEngine
import WalletDomainModels

class AppConfigurator {
    static var storeHelper: StoreHelperProtocol = StoreHelper.instance
    static let transactionLogController = TransactionLogController(config: TransactionLogConfig())

    static func configureApp() {
        bootstrapWalletStrings()
        bootstrapWalletConfiguration()
        bootstrapWalletDependencies()

        // A fresh install can inherit a prior holder's keychain, which survives uninstall.
        // Record the first launch synchronously, before the fallible async wipe, so a later cold launch is never mistaken for a first launch and can't re-wipe the user's PIN and documents.
        let isFirstLaunch = storeHelper.getValue(forKey: .hasAppBeenLaunchedBefore) != true
        if isFirstLaunch {
            clearLocalStoreForFreshInstall()
            // Record after clearLocalStoreForFreshInstall(): its clearAllData() would otherwise wipe the flag.
            storeHelper.save(true, type: Bool.self, forKey: .hasAppBeenLaunchedBefore)
        }

        FontBook.mainFont = AppMainFont()
        FontBook.headingFont = AppHeadingFont()

        Task {
            if isFirstLaunch { await clearCredentialStoreForFreshInstall() }
            try await WalletKitController.instance.loadDocuments()
            await MainActor.run {
                NotificationCenter.default.post(
                    name: DocumentsConstants.Notifications.documentsWasReordered,
                    object: nil
                )
            }
        }
    }

    /// Synchronous half of the fresh-install wipe (UserDefaults + keychain), run before `routeStart()` reads the PIN so a leftover hash can't route to entry instead of setup.
    private static func clearLocalStoreForFreshInstall() {
        storeHelper.removeValue(forKey: .authPincode)
        storeHelper.clearAllData()
        UIApplication.shared.applicationIconBadgeNumber = 0
    }

    /// Asynchronous, best-effort half of the fresh-install wipe (EUDI document + transaction-log stores).
    /// Must never run on a later launch — by then the stores hold the current user's own documents, and clearing them would be data loss.
    private static func clearCredentialStoreForFreshInstall() async {
        try? await WalletKitController.instance.clearAllDocuments()
        try? await transactionLogController.transactionLogStorage.deleteAll()
    }

    private static func bootstrapWalletStrings() {
        WalletStrings.configure(AppWalletStringsProvider())
    }

    private static func bootstrapWalletDependencies() {
        // Step 1 — install the host-supplied bridges. The transactionLogStore is critical: `WalletKitController` constructs `WalletKitTransactionLoggerBridge` against it during its (lazy) init, so the kit singleton cannot be evaluated until the store is in place.
        // The transaction-log storage is constructed here (host-owned) instead of by WalletDependencies — keeps WalletDependencies from needing to know how to build SDK-coupled storage, which matters once DefaultTransactionLogStorage moves into WalletEngine in Phase H and WalletCore loses the SDK dep.
        let transactionLogStorage = DefaultTransactionLogStorage(store: transactionLogController.transactionLogStore)
        WalletDependencies.configure(
            transactionLogStore: transactionLogController.transactionLogStore,
            transactionLogStorage: transactionLogStorage,
            templatePresenter: AppWalletTemplatePresenter(),
            documentsRefresher: AppWalletDocumentsRefresher(),
            remoteSharingPresenter: WalletRemoteSharingFactory(),
            authGate: AppWalletAuthGate(),
            onboardingLauncher: AppWalletOnboardingLauncher()
        )

        // Step 2 — now safe to first-evaluate `WalletKitController.instance` (the bridge inside it reads `WalletDependencies.transactionLogStore`, set above). The error formatter then preloads metadata via that same singleton; install it second so the chain is honoured.
        // Also install the session-manager factories so WalletSharing can construct fresh proximity/remote sessions per flow without seeing WalletEngine. The closures capture the concrete-class initialisers — the engine module is referenced here exactly once for each, and the rest of the wallet stays SDK-blind.
        WalletDependencies.setWalletController(WalletKitController.instance)
        WalletDependencies.setWalletErrorFormatter(WalletErrorFormatter())
        WalletDependencies.setProximitySessionFactory { WalletProximitySessionManager() }
        WalletDependencies.setRemoteSessionFactory { WalletRemoteSessionManager() }

        // Step 3 — construct the two polling services + the lifecycle coordinator that owns them. Both services were previously `.shared` singletons; they now have a single owner (`WalletDependencies.walletLifecycle`) so start/stop pair with auth state, not routing, and the deferred-issuance alert can be gated by the host app.
        let notificationService = LocalNotificationService()
        let revocationService = DocumentRevocationService(
            walletController: WalletDependencies.walletController,
            notificationScheduler: notificationService
        )
        let deferredCoordinator = DeferredIssuanceCoordinator(
            walletController: WalletDependencies.walletController,
            notificationScheduler: notificationService
        )
        let walletLifecycle = WalletLifecycleCoordinator(
            revocationService: revocationService,
            deferredCoordinator: deferredCoordinator
        )
        WalletDependencies.setWalletLifecycle(walletLifecycle)
        DocumentsProcessor.bootstrap(revocationService: revocationService)
        WalletGalleryConfiguration.configure(
            images: WalletGalleryImages(
                documentInfo: R.image.documentInfo.image,
                deleteDocument: R.image.deleteDocument.image
            )
        )
    }

    private static func bootstrapWalletConfiguration() {
        guard let url = Bundle.main.url(forResource: "wallet-config", withExtension: "json") else {
            fatalError("wallet-config.json not found in app bundle — ensure it is added to the app target's Copy Bundle Resources phase.")
        }
        do {
            let data = try Data(contentsOf: url)
            let config = try JSONDecoder().decode(WalletConfiguration.self, from: data)
            WalletConfiguration.configure(config)
        } catch {
            fatalError("Failed to decode wallet-config.json: \(error)")
        }
    }
}
