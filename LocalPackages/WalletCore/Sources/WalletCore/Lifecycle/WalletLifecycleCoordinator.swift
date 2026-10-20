import Foundation
import WalletDomainModels
import DiiaMVPModule
import DiiaCommonTypes

/// Owns the lifecycle of wallet-wide background services that should run only
/// while a user session is active (post-login, pre-logout):
/// - `DocumentRevocationService` — periodic revocation-status polling.
/// - `DeferredIssuanceCoordinator` — OID4VCI deferred-credential polling and
///   the completion alert when a deferred document finishes issuing.
///
/// Replaces the previous pattern of accessing `DocumentRevocationService.shared`
/// / `DeferredIssuanceCoordinator.shared` from scattered call sites (AppRouter,
/// AuthorizationStateHandler, card view models, sharing presenters) — there is
/// now a single coordinator owned by the app composition root and exposed via
/// `WalletDependencies.walletLifecycle`. Start/stop pairs with auth state, not
/// routing.
///
/// **Alert gating** (`alertHostProvider`): the host app supplies the closure
/// that returns the foreground `BaseView` *only* when it is appropriate to
/// present a deferred-completion alert (per product: Documents tab at nav root,
/// no modal up). Returning `nil` means "not now" — the alert is queued and
/// retried on the next `flushPendingAlerts()` call (tab change, …).
public final class WalletLifecycleCoordinator {
    public let revocationService: DocumentRevocationService
    public let deferredCoordinator: DeferredIssuancePolling

    /// Host-app-supplied alert gate. Returning `nil` causes the lifecycle to
    /// queue the alert and retry later on `flushPendingAlerts()`. Set when the
    /// authenticated UI is mounted; cleared in `endSession()`.
    public var alertHostProvider: (() -> BaseView?)?

    /// Most-recent unpresented deferred-issuance completion alert. Holds at
    /// most one entry — if a second alert arrives before the first flushes,
    /// it replaces the old one (per product: "show *the* one"). Cleared on
    /// successful flush and on `endSession()`.
    private var pendingAlert: AlertTemplate?

    public init(
        revocationService: DocumentRevocationService,
        deferredCoordinator: DeferredIssuancePolling
    ) {
        self.revocationService = revocationService
        self.deferredCoordinator = deferredCoordinator
    }

    /// Call when the authenticated session begins (e.g. login success). Starts
    /// both polling services. The deferred coordinator hands every completion
    /// alert back to this coordinator via the injected closure so we can
    /// route it through the gate (present now / queue / drop).
    public func startSession() {
        revocationService.startMonitoring()
        deferredCoordinator.start { [weak self] template in
            self?.handleDeferredAlert(template)
        }
    }

    /// Call when the authenticated session ends (e.g. logout). Stops both
    /// services, clears revocation cache, drops the alert gate + any pending
    /// alert so a fresh session starts from a clean slate.
    public func endSession() {
        deferredCoordinator.stop()
        revocationService.stopMonitoring()
        revocationService.clearCache()
        alertHostProvider = nil
        pendingAlert = nil
    }

    /// Public flush hook. Call when the foreground UI state has changed such
    /// that a previously-queued alert may now be presentable (e.g. the user
    /// just landed on the Documents tab root). Cheap when there is nothing
    /// queued.
    ///
    /// **Must be called on the main thread.** Not declared `@MainActor` so
    /// callers in non-isolated protocol methods (e.g.
    /// `DocumentsCollectionContext.documentsDidAppear`) can call it without
    /// cascading isolation through the vendored `DocumentsCore` protocols. All
    /// current call paths originate from UIKit lifecycle / UI flows, which
    /// are always on the main thread; `dispatchPrecondition` enforces this
    /// at runtime.
    public func flushPendingAlerts() {
        dispatchPrecondition(condition: .onQueue(.main))
        guard let template = pendingAlert,
              let host = alertHostProvider?() else { return }
        pendingAlert = nil
        WalletDependencies.templatePresenter.handle(template, in: host) { _ in }
    }

    /// Route a deferred-completion alert through the host's gate: present
    /// immediately if the host is currently the right surface, else queue it
    /// (overwriting any older pending alert — only the most recent matters
    /// for UX) and let the next `flushPendingAlerts()` call surface it.
    ///
    /// Same main-thread invariant as `flushPendingAlerts()`. Called from the
    /// deferred coordinator's `presentAlert` closure, which is invoked inside
    /// `MainActor.run` in `handlePollOutcome` — always on main.
    private func handleDeferredAlert(_ template: AlertTemplate) {
        dispatchPrecondition(condition: .onQueue(.main))
        if let host = alertHostProvider?() {
            WalletDependencies.templatePresenter.handle(template, in: host) { _ in }
            return
        }
        pendingAlert = template
    }
}
