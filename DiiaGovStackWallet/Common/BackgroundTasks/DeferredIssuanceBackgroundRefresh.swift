import Foundation
import BackgroundTasks
import WalletCore

/// Opportunistic OS-level background polling for deferred OID4VCI credentials.
///
/// This complements the continuous in-app loop in `DeferredIssuanceCoordinator`, which only runs while the app is foreground/active.
/// iOS cannot poll "continuously" while backgrounded — `BGAppRefreshTask` is scheduled by the system opportunistically (typically minutes-to-hours apart, throttled by usage patterns, Low Power Mode, and the user's Background App Refresh setting).
///
/// Requirements wired alongside this:
/// - `taskIdentifier` is listed under `BGTaskSchedulerPermittedIdentifiers` in Info.plist.
/// - `fetch` is present in `UIBackgroundModes` in Info.plist.
/// - `register()` is called synchronously during `application(_:didFinishLaunchingWithOptions:)`.
enum DeferredIssuanceBackgroundRefresh {
    /// Must match the Info.plist `BGTaskSchedulerPermittedIdentifiers` entry exactly.
    static let taskIdentifier = "ua.govstack.digitalwallet.deferred-issuance-refresh"

    /// Earliest the system should consider running the refresh, measured from submission.
    /// The system may run it much later, or skip it entirely — this is a floor, not a schedule.
    private static let earliestInterval: TimeInterval = 15 * 60 // 15 minutes

    /// Register the launch handler.
    /// MUST be called synchronously from `application(_:didFinishLaunchingWithOptions:)` before it returns — `BGTaskScheduler` traps on registration after launch completes.
    static func register() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: taskIdentifier, using: nil) { task in
            // The identifier is registered only for BGAppRefreshTaskRequest, so this cast is safe.
            guard let refreshTask = task as? BGAppRefreshTask else {
                task.setTaskCompleted(success: false)
                return
            }
            handle(task: refreshTask)
        }
    }

    /// Submit a refresh request if any deferred document is still awaiting issuance.
    /// Call when the app enters the background. Safe to call repeatedly — a new submit replaces any pending request for the same identifier.
    static func scheduleIfNeeded() {
        guard WalletDependencies.walletLifecycle.deferredCoordinator.hasPendingDeferredDocuments else { return }
        submit()
    }

    private static func submit() {
        let request = BGAppRefreshTaskRequest(identifier: taskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: earliestInterval)
        try? BGTaskScheduler.shared.submit(request)
    }

    private static func handle(task: BGAppRefreshTask) {
        let coordinator = WalletDependencies.walletLifecycle.deferredCoordinator
        guard coordinator.hasPendingDeferredDocuments else {
            task.setTaskCompleted(success: true)
            return
        }

        let work = Task {
            await coordinator.pollOnceForBackgroundRefresh()
            // Chain the next opportunistic refresh only while work remains.
            if coordinator.hasPendingDeferredDocuments {
                submit()
            }
            task.setTaskCompleted(success: true)
        }

        // iOS revokes the execution window after a short, system-decided budget — cancel cleanly and report incompletion so the system can reschedule.
        task.expirationHandler = {
            work.cancel()
            task.setTaskCompleted(success: false)
        }
    }
}
