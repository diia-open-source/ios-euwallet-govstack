//
//  DeferredIssuanceCoordinator.swift
//

import UIKit
import DiiaMVPModule
import DiiaCommonTypes
import DiiaUIComponents
import WalletDocumentsCore
import WalletCore
import WalletDomainModels

/// Drives polling of the OID4VCI deferred-credential endpoint for any `WalletStorage.Document.isDeferred` records.
///
/// Coverage is two-tiered:
/// - **Foreground:** a continuous self-rescheduling loop polls every `pollIntervalSeconds` for as long as any deferred doc remains.
/// - **Backgrounding:** a finite-length `beginBackgroundTask` grace ping runs one immediate poll right after the app is backgrounded (iOS grants ~30s of wall-clock for this).
/// - **Fully backgrounded:** the host registers a `BGAppRefreshTask` that calls `pollOnceForBackgroundRefresh()` when the system opportunistically wakes the app. That cadence is system-controlled (minutes-to-hours apart) — iOS does not allow truly continuous background polling.
///
/// All foreground state (`pollingTask`, the grace-task id) is touched on the main thread; the network poll itself runs off-main and hops back via `MainActor.run`.
public final class DeferredIssuanceCoordinator: DeferredIssuancePolling {
    private let walletController: WalletKitProtocol
    private var presentAlert: ((AlertTemplate) -> Void)?
    private var foregroundObserver: NSObjectProtocol?
    private var backgroundObserver: NSObjectProtocol?
    private var pollingTask: Task<Void, Never>?
    private var backgroundGraceTaskId: UIBackgroundTaskIdentifier = .invalid
    private var isStarted = false
    /// True while a deferred-issuance poll cycle is active — held from the network request through the post-poll reload and completion alert, not just the request itself.
    /// Serialises the foreground loop, the background grace ping, and the OS refresh so they never poll the same document concurrently (concurrent requests race on its Secure Enclave key, `SecKeyCreate … -50`, and corrupt each other into a contradictory Failure+Success pair of alerts) and so a second `handlePollOutcome` can't overlap the first's storage mutation.
    /// Touched only on the main actor (via `beginPollIfIdle`/`endPoll`).
    private var isPollInFlight = false
    private let notificationScheduler: LocalNotificationScheduling

    public init(
        walletController: WalletKitProtocol,
        notificationScheduler: LocalNotificationScheduling
    ) {
        self.walletController = walletController
        self.notificationScheduler = notificationScheduler
    }

    public var hasPendingDeferredDocuments: Bool {
        !walletController.fetchDeferredDocuments().isEmpty
    }

    /// Activate observation. `presentAlert` is called once per completed poll
    /// that produced an issued outcome; the receiver (typically
    /// `WalletLifecycleCoordinator`) decides whether to present the alert
    /// immediately, queue it for later, or drop it. The coordinator itself
    /// no longer knows about hosts or gating — separation of concerns:
    /// polling here, presentation policy upstream.
    public func start(presentAlert: @escaping (AlertTemplate) -> Void) {
        self.presentAlert = presentAlert
        guard !isStarted else {
            triggerPollIfNeeded()
            return
        }
        isStarted = true
        // Prompt once for local-notification permission so a deferred outcome that lands while the app is backgrounded can surface as a banner. No-op after the user has decided.
        notificationScheduler.requestAuthorizationIfNeeded()
        foregroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.triggerPollIfNeeded()
        }
        // When the app is backgrounded, the foreground loop's `Task.sleep` is suspended by iOS.
        // Spend the brief grace window iOS grants on one last immediate poll so a credential that became ready just before backgrounding still lands.
        backgroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.runBackgroundGracePoll()
        }
        triggerPollIfNeeded()
    }

    public func stop() {
        if let foregroundObserver {
            NotificationCenter.default.removeObserver(foregroundObserver)
        }
        if let backgroundObserver {
            NotificationCenter.default.removeObserver(backgroundObserver)
        }
        foregroundObserver = nil
        backgroundObserver = nil
        cancelPolling()
        endBackgroundGraceTask()
        isStarted = false
    }

    deinit {
        stop()
    }

    /// Ask the coordinator to start polling now if any deferred docs exist and no poll is in flight.
    /// Called externally after a fresh deferred issuance, since `start()` only auto-triggers on app foreground transitions.
    public func kick() {
        triggerPollIfNeeded()
    }

    // MARK: - Foreground continuous loop

    private func cancelPolling() {
        pollingTask?.cancel()
        pollingTask = nil
    }

    /// Claim the single poll slot if it is free and there is work to do.
    /// Returns `false` (and starts nothing) when another poll is already running or no deferred docs remain — this is the mutual-exclusion gate that stops the foreground loop and the grace ping from issuing the same document twice at once.
    @MainActor
    private func beginPollIfIdle() -> Bool {
        guard hasPendingDeferredDocuments else { return false }
        guard !isPollInFlight else { return false }
        isPollInFlight = true
        return true
    }

    @MainActor
    private func endPoll() {
        isPollInFlight = false
    }

    private func triggerPollIfNeeded() {
        guard isStarted, hasPendingDeferredDocuments, pollingTask == nil else { return }
        schedulePoll()
    }

    private func schedulePoll() {
        pollingTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(Constants.pollIntervalSeconds) * 1_000_000_000)
            guard let self, !Task.isCancelled else { return }

            guard await self.beginPollIfIdle() else {
                await MainActor.run { [weak self] in self?.pollingTask = nil }
                return
            }
            let outcome = await self.walletController.requestDeferredIssuanceForAll()
            // Keep the in-flight slot claimed across the reload + alert, not just the network request, so a foreground/grace/refresh trigger can't start a second poll (and a second `handlePollOutcome`) while this one is still mutating storage and presenting.
            await self.handlePollOutcome(outcome)

            await MainActor.run { [weak self] in
                guard let self else { return }
                self.endPoll()
                self.pollingTask = nil
                self.triggerPollIfNeeded()
            }
        }
    }

    /// Apply a completed poll: delete any errored docs, reload, then on the main actor refresh the UI, post a background notification if needed, and present the single completion alert.
    /// Awaited by each poll path while the in-flight slot is still held, so the next `triggerPollIfNeeded()` only runs after `endPoll()`.
    private func handlePollOutcome(_ outcome: DeferredPollOutcome) async {
        // Remove any deferred document whose poll errored — the card disappears and a generic failure alert is shown (per product).
        // Caveat: `failedIds` lumps transient network errors with terminal issuer rejections (SDK can't tell them apart), so a network blip also deletes the doc and alerts.
        for failedId in outcome.failedIds {
            try? await walletController.deleteDeferredDocument(with: failedId)
        }
        do {
            try await walletController.loadDocuments()
        } catch { }
        await MainActor.run {
            WalletDependencies.documentsRefresher.walletDidRefreshDocuments()
            self.postBackgroundCompletionNotificationIfNeeded(for: outcome)
            self.presentCompletionAlert(for: outcome)
        }
    }

    private func presentCompletionAlert(for outcome: DeferredPollOutcome) {
        guard let presentAlert else { return }
        // At most one alert per poll — `TemplateHandler.handle` has no queue, so two calls would stack modals.
        // Failure wins over success: a failed poll deletes the doc, so the alert is the user's only signal; an issued doc shows up in the wallet on its own.
        if !outcome.failedIds.isEmpty {
            presentAlert(Constants.failedAlert)
        } else if !outcome.issuedIds.isEmpty {
            presentAlert(Constants.issuedAlert)
        }
    }

    /// Post a local notification for a poll that resolved while the app was backgrounded, so the user learns the outcome without reopening.
    /// Foreground resolutions stay silent here — the in-app alert already shows; a backgrounded resolution also queues that alert (via the lifecycle coordinator) so it still appears on reopen.
    /// Mirrors `presentCompletionAlert`'s failure-priority: at most one notification per poll.
    private func postBackgroundCompletionNotificationIfNeeded(for outcome: DeferredPollOutcome) {
        guard UIApplication.shared.applicationState == .background else { return }
        if !outcome.failedIds.isEmpty {
            notificationScheduler.schedule(
                title: WalletStringKey.deferredIssuanceFailedTitle.localized(),
                body: WalletStringKey.deferredIssuanceFailedDescription.localized(),
                identifier: Constants.failureNotificationIdentifier
            )
        } else if !outcome.issuedIds.isEmpty {
            notificationScheduler.schedule(
                title: WalletStringKey.deferredIssuanceCompletedTitle.localized(),
                body: WalletStringKey.deferredIssuanceCompletedDescription.localized(),
                identifier: Constants.successNotificationIdentifier
            )
        }
    }

    // MARK: - Background grace ping (finite-length task on backgrounding)

    private func runBackgroundGracePoll() {
        guard hasPendingDeferredDocuments else { return }
        // Do NOT cancel the foreground loop here: if its request is already in flight, `Task.cancel()` can't stop the in-flight SDK network call, so cancelling only lets this grace ping start a *second* concurrent request on the same document — the race that corrupts the Secure Enclave key.
        // Mutual exclusion is enforced by `beginPollIfIdle` instead; the background assertion below just gives whichever single request is running time to finish before iOS suspends us.
        let application = UIApplication.shared
        backgroundGraceTaskId = application.beginBackgroundTask(withName: Constants.gracePollTaskName) { [weak self] in
            // iOS is about to revoke the granted time — release the assertion.
            self?.endBackgroundGraceTask()
        }
        guard backgroundGraceTaskId != .invalid else { return }

        Task { [weak self] in
            guard let self else { return }
            guard await self.beginPollIfIdle() else {
                await MainActor.run { [weak self] in self?.endBackgroundGraceTask() }
                return
            }
            let outcome = await self.walletController.requestDeferredIssuanceForAll()
            await self.handlePollOutcome(outcome)
            await MainActor.run { [weak self] in
                guard let self else { return }
                self.endPoll()
                self.endBackgroundGraceTask()
                self.triggerPollIfNeeded()
            }
        }
    }

    private func endBackgroundGraceTask() {
        guard backgroundGraceTaskId != .invalid else { return }
        UIApplication.shared.endBackgroundTask(backgroundGraceTaskId)
        backgroundGraceTaskId = .invalid
    }

    // MARK: - OS background refresh (BGAppRefreshTask)

    /// One poll cycle driven by the host's `BGAppRefreshTask` handler while the app is fully backgrounded.
    /// Runs a single poll + reload to completion; the host decides whether to chain another refresh based on `hasPendingDeferredDocuments`.
    public func pollOnceForBackgroundRefresh() async {
        // The in-flight guard (not cancellation) keeps this from racing the foreground loop.
        guard await beginPollIfIdle() else { return }
        let outcome = await walletController.requestDeferredIssuanceForAll()
        await handlePollOutcome(outcome)
        await MainActor.run {
            self.endPoll()
            self.triggerPollIfNeeded()
        }
    }
}

private extension DeferredIssuanceCoordinator {
    enum Constants {
        /// Cadence of the continuous foreground poll loop. Also the delay before the first poll after a fresh deferred issuance, giving the issuer a moment to register the request.
        static let pollIntervalSeconds: UInt64 = 60

        static let gracePollTaskName = "deferred-issuance-grace-poll"

        // Local-notification identifiers for backgrounded deferred outcomes.
        // The `deferred-issuance` prefix is matched in `AppDelegate.userNotificationCenter(_:willPresent:…)` to suppress these banners while the app is foreground.
        static let successNotificationIdentifier = "deferred-issuance.completed"
        static let failureNotificationIdentifier = "deferred-issuance.failed"

        static let issuedAlert = AlertTemplate(
            type: .middleCenterIconBlackButtonAlert,
            isClosable: false,
            data: AlertTemplateData(
                icon: .doneBlackRound,
                title: WalletStringKey.deferredIssuanceCompletedTitle.localized(),
                description: WalletStringKey.deferredIssuanceCompletedDescription.localized(),
                mainButton: AlertButtonModel(
                    title: WalletStringKey.issuanceSuccessButton.localized(),
                    icon: nil,
                    action: .ok
                ),
                alternativeButton: nil
            )
        )

        static let failedAlert = AlertTemplate(
            type: .middleCenterIconBlackButtonAlert,
            isClosable: false,
            data: AlertTemplateData(
                icon: .attentionBlackRound,
                title: WalletStringKey.deferredIssuanceFailedTitle.localized(),
                description: WalletStringKey.deferredIssuanceFailedDescription.localized(),
                mainButton: AlertButtonModel(
                    title: WalletStringKey.generalProblemOk.localized(),
                    icon: nil,
                    action: .ok
                ),
                alternativeButton: nil
            )
        )
    }
}
