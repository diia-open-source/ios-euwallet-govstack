import Foundation
import WalletDomainModels
import DiiaCommonTypes
import DiiaMVPModule

/// App-supplied bridge for presenting `DiiaCommonServices`'s template-alert flow from inside `WalletCore`.
///
/// The package never imports `DiiaCommonServices` directly — every alert it would otherwise present
/// is routed through this protocol. The host app installs an adapter at launch that forwards to
/// `TemplateHandler.handle(...)`.
public protocol WalletTemplatePresenting {
    func handle(
        _ template: AlertTemplate,
        in view: BaseView,
        callback: @escaping (AlertTemplateAction) -> Void
    )
}

/// App-supplied hook that the package invokes whenever the wallet's local document store
/// has just been refreshed (e.g., after deferred-issuance polling completes).
///
/// The app implementation typically reloads `DocumentsProcessor` providers and posts
/// `documentsWasReordered` so the UI reacts.
public protocol WalletDocumentsRefreshing {
    @MainActor
    func walletDidRefreshDocuments()
}

/// App-supplied factory for the remote-sharing (OID4VP) presentation module.
///
/// Lets wallet packages (e.g. `WalletIssuing`) launch a remote-sharing flow as part
/// of the authorization-code redirect handshake without depending directly on
/// `WalletSharing`. The host app composition root knows both features and constructs
/// the concrete module.
public protocol WalletRemoteSharingPresenting {
    func makeRemoteSharingModule(
        link: String,
        redirectCallback: @escaping (String) -> Void
    ) -> BaseModule
}

/// App-supplied pre-share authentication gate (PIN / biometry).
///
/// The wallet sharing flow asks the host app to authenticate the user before transmitting
/// credentials. The app constructs whichever PIN / biometry module it ships with and
/// invokes the callbacks accordingly.
public protocol WalletAuthGating {
    func presentAuthBeforeSend(
        in view: BaseView,
        onSuccess: @escaping () -> Void,
        onCancel: @escaping () -> Void
    )
}

/// Feature-supplied OID4VCI deferred-issuance polling service.
///
/// The concrete implementation lives in `WalletIssuing` so the feature
/// owns its polling cadence + alert copy without touching WalletCore.
/// `WalletLifecycleCoordinator` holds this protocol and drives start/stop;
/// presenters inside `WalletIssuing` can `kick()` it to force an immediate
/// poll after a deferred credential is enqueued.
public protocol DeferredIssuancePolling: AnyObject {
    func start(presentAlert: @escaping (AlertTemplate) -> Void)
    func stop()
    func kick()

    /// Whether any deferred documents are still awaiting issuance.
    /// The host uses this to decide whether to schedule / chain an OS background-refresh task.
    var hasPendingDeferredDocuments: Bool { get }

    /// Run a single poll cycle to completion, off the normal foreground timer.
    /// Invoked by the host's `BGAppRefreshTask` handler so a deferred credential can be picked up while the app is backgrounded.
    /// Returns once the poll + document reload has finished.
    func pollOnceForBackgroundRefresh() async
}

/// App-supplied launcher for the wallet onboarding / "create wallet" flow.
///
/// When the sharing flow discovers there is no wallet yet (or no PID to back the share),
/// it asks the host app to navigate the user to a wallet-creation flow appropriate for
/// the current deployment. The app composition root knows how to assemble that.
public protocol WalletOnboardingLaunching {
    func presentOnboardingFlow(in view: BaseView, flowCoordinator: FlowCoordinatorProtocol)
}

/// Global access point for runtime dependencies that `WalletCore` cannot construct itself.
///
/// Must be configured exactly once at app launch, before any wallet controller runs.
/// Parallel pattern to `WalletConfiguration.configure(_:)` and `WalletStrings.configure(_:)`.
public enum WalletDependencies {
    public static func configure(
        transactionLogStore: TransactionLogStore,
        transactionLogStorage: TransactionLogStorage,
        templatePresenter: WalletTemplatePresenting,
        documentsRefresher: WalletDocumentsRefreshing,
        remoteSharingPresenter: WalletRemoteSharingPresenting,
        authGate: WalletAuthGating,
        onboardingLauncher: WalletOnboardingLaunching
    ) {
        _transactionLogStore = transactionLogStore
        _transactionLogStorage = transactionLogStorage
        _templatePresenter = templatePresenter
        _documentsRefresher = documentsRefresher
        _remoteSharingPresenter = remoteSharingPresenter
        _authGate = authGate
        _onboardingLauncher = onboardingLauncher
    }

    /// Install the domain-facing port to the EUDI wallet kit. **Must be called after** `configure(...)`.
    /// Same chicken-and-egg as `setWalletLifecycle`: the concrete `WalletKitController` constructs `WalletKitTransactionLoggerBridge` during its (lazy) init and that bridge reads `WalletDependencies.transactionLogStore`, so the controller cannot be evaluated as a `configure(...)` argument — by then the store isn't set yet.
    /// The host calls `setWalletController(WalletKitController.instance)` right after `configure(...)`; at that point the store is in place, the singleton inits cleanly, and the bridge wires up against a valid store.
    public static func setWalletController(_ controller: WalletKitProtocol) {
        _walletController = controller
    }

    /// Install the domain-facing port to the wallet error formatter. **Must be called after** `setWalletController(_:)`.
    /// The concrete `WalletErrorFormatter.preloadMetadata()` reaches into `WalletKitController.instance.fetchAllStorageDocuments()` (WalletCore-internal call, not on the protocol), which requires the controller singleton to have already initialised cleanly.
    public static func setWalletErrorFormatter(_ formatter: WalletErrorFormatting) {
        _walletErrorFormatter = formatter
    }

    /// Install the factory used by `WalletSharing` to construct proximity (BLE) sharing sessions on demand.
    /// One new session is built per sharing flow — the factory closure returns a fresh `WalletProximitySessionManaging` each call.
    /// Concrete session managers live in WalletEngine and import the SDK; the closure is the only place where WalletEngine is referenced outside the composition root.
    public static func setProximitySessionFactory(_ factory: @escaping () -> WalletProximitySessionManaging) {
        _proximitySessionFactory = factory
    }

    /// Install the factory used by `WalletSharing` to construct remote (OID4VP) sharing sessions on demand.
    /// Same shape as `setProximitySessionFactory` — one session per flow, factory closure owned by the host.
    public static func setRemoteSessionFactory(_ factory: @escaping () -> WalletRemoteSessionManaging) {
        _remoteSessionFactory = factory
    }

    /// Install the wallet-lifecycle coordinator. **Must be called after** `setWalletController(_:)` — the coordinator's polling services (DeferredIssuanceCoordinator's default arg + DocumentRevocationService) reach back through `WalletDependencies.walletController`, so the controller slot must already be populated.
    public static func setWalletLifecycle(_ coordinator: WalletLifecycleCoordinator) {
        _walletLifecycle = coordinator
    }

    /// Persistence adapter the app installs at launch. Stays a `TransactionLogStore`
    /// (blob CRUD) so the host code never needs to import upstream eudi-* modules.
    public static var transactionLogStore: TransactionLogStore {
        guard let value = _transactionLogStore else {
            fatalError("WalletDependencies.transactionLogStore accessed before WalletDependencies.configure(...) was called — bootstrap wallet dependencies at app launch.")
        }
        return value
    }

    /// Domain-facing read/delete service backed by the configured `TransactionLogStore`.
    /// Wallet packages (Transactions, Menu, etc.) consume this — they see only domain
    /// types (`TransactionLogEntry`, `Credential`).
    public static var transactionLogStorage: TransactionLogStorage {
        guard let value = _transactionLogStorage else {
            fatalError("WalletDependencies.transactionLogStorage accessed before WalletDependencies.configure(...) was called — bootstrap wallet dependencies at app launch.")
        }
        return value
    }

    public static var templatePresenter: WalletTemplatePresenting {
        guard let value = _templatePresenter else {
            fatalError("WalletDependencies.templatePresenter accessed before WalletDependencies.configure(...) was called — bootstrap wallet dependencies at app launch.")
        }
        return value
    }

    public static var documentsRefresher: WalletDocumentsRefreshing {
        guard let value = _documentsRefresher else {
            fatalError("WalletDependencies.documentsRefresher accessed before WalletDependencies.configure(...) was called — bootstrap wallet dependencies at app launch.")
        }
        return value
    }

    public static var remoteSharingPresenter: WalletRemoteSharingPresenting {
        guard let value = _remoteSharingPresenter else {
            fatalError("WalletDependencies.remoteSharingPresenter accessed before WalletDependencies.configure(...) was called — bootstrap wallet dependencies at app launch.")
        }
        return value
    }

    public static var authGate: WalletAuthGating {
        guard let value = _authGate else {
            fatalError("WalletDependencies.authGate accessed before WalletDependencies.configure(...) was called — bootstrap wallet dependencies at app launch.")
        }
        return value
    }

    public static var onboardingLauncher: WalletOnboardingLaunching {
        guard let value = _onboardingLauncher else {
            fatalError("WalletDependencies.onboardingLauncher accessed before WalletDependencies.configure(...) was called — bootstrap wallet dependencies at app launch.")
        }
        return value
    }

    /// Owns `DocumentRevocationService` + `DeferredIssuanceCoordinator` and the
    /// deferred-issuance alert gate. Start/stop pair with the authenticated
    /// session (login → `startSession()`, logout → `endSession()`); the host
    /// app installs `alertHostProvider` once the UI is mounted to control
    /// where (or whether) deferred-completion alerts get presented.
    public static var walletLifecycle: WalletLifecycleCoordinator {
        guard let value = _walletLifecycle else {
            fatalError("WalletDependencies.walletLifecycle accessed before WalletDependencies.configure(...) was called — bootstrap wallet dependencies at app launch.")
        }
        return value
    }

    /// Domain-facing port to the EUDI wallet kit.
    /// Features call this instead of `WalletKitController.instance` so they never see the SDK.
    /// Bootstrapped in Phase D when `configure(...)` learns the `walletController:` parameter and the host passes the concrete `WalletKitController.instance`.
    /// Accessor fatalErrors until then — Phase D ships configure + host bootstrap + feature call-site replacements in a single MR, so no one is expected to call this in the Phase C interim.
    public static var walletController: WalletKitProtocol {
        guard let value = _walletController else {
            fatalError("WalletDependencies.walletController accessed before WalletDependencies.configure(...) was called — bootstrap wallet dependencies at app launch.")
        }
        return value
    }

    /// Domain-facing port to the wallet error formatter (claim/document display-name resolution plus structured/legacy error → localized string conversion).
    /// Same Phase D timing as `walletController`.
    public static var walletErrorFormatter: WalletErrorFormatting {
        guard let value = _walletErrorFormatter else {
            fatalError("WalletDependencies.walletErrorFormatter accessed before WalletDependencies.configure(...) was called — bootstrap wallet dependencies at app launch.")
        }
        return value
    }

    /// Construct a fresh proximity (BLE) sharing session.
    /// Each call returns a new `WalletProximitySessionManaging` instance — sessions are not shared across sharing flows.
    public static func makeProximitySession() -> WalletProximitySessionManaging {
        guard let factory = _proximitySessionFactory else {
            fatalError("WalletDependencies.makeProximitySession() called before setProximitySessionFactory(_:) — bootstrap wallet dependencies at app launch.")
        }
        return factory()
    }

    /// Construct a fresh remote (OID4VP) sharing session.
    /// Each call returns a new `WalletRemoteSessionManaging` instance — sessions are not shared across sharing flows.
    public static func makeRemoteSession() -> WalletRemoteSessionManaging {
        guard let factory = _remoteSessionFactory else {
            fatalError("WalletDependencies.makeRemoteSession() called before setRemoteSessionFactory(_:) — bootstrap wallet dependencies at app launch.")
        }
        return factory()
    }

    private static var _transactionLogStore: TransactionLogStore?
    private static var _transactionLogStorage: TransactionLogStorage?
    private static var _templatePresenter: WalletTemplatePresenting?
    private static var _documentsRefresher: WalletDocumentsRefreshing?
    private static var _remoteSharingPresenter: WalletRemoteSharingPresenting?
    private static var _authGate: WalletAuthGating?
    private static var _onboardingLauncher: WalletOnboardingLaunching?
    private static var _walletLifecycle: WalletLifecycleCoordinator?
    private static var _walletController: WalletKitProtocol?
    private static var _walletErrorFormatter: WalletErrorFormatting?
    private static var _proximitySessionFactory: (() -> WalletProximitySessionManaging)?
    private static var _remoteSessionFactory: (() -> WalletRemoteSessionManaging)?
}
