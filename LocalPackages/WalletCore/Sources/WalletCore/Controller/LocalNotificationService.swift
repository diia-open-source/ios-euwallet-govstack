//
//  LocalNotificationService.swift
//

import Foundation
import UserNotifications
import WalletDomainModels

// MARK: - Scheduling Port

/// Abstraction over the system notification center so background services
/// (e.g. `DocumentRevocationService`) can surface an OS banner without coupling
/// to `UNUserNotificationCenter` directly — and so tests can substitute a spy.
public protocol LocalNotificationScheduling: Sendable {
    /// Ask for alert/sound authorization once, only if the user has never been
    /// prompted. A no-op after any determination (granted or denied) so we never
    /// re-prompt a user who already decided.
    func requestAuthorizationIfNeeded()

    /// Post a local notification for immediate delivery. Reusing an existing
    /// `identifier` replaces the prior notification rather than stacking a
    /// duplicate.
    func schedule(title: String, body: String, identifier: String)
}

// MARK: - Concrete Service

/// Thin `UNUserNotificationCenter` wrapper used to deliver local notifications.
///
/// Note: the in-app revocation poller only runs while the app is foregrounded,
/// so these banners primarily surface a revocation the user would otherwise
/// miss while on a non-Documents screen. Delivery while the app is in the
/// foreground requires the app's `UNUserNotificationCenterDelegate` to opt in
/// via `willPresent` (the host already owns that delegate).
public final class LocalNotificationService: LocalNotificationScheduling, @unchecked Sendable {

    private let center: UNUserNotificationCenter

    public init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    public func requestAuthorizationIfNeeded() {
        center.getNotificationSettings { [center] settings in
            guard settings.authorizationStatus == .notDetermined else { return }
            center.requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
        }
    }

    public func schedule(title: String, body: String, identifier: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        // `nil` trigger delivers as soon as the system processes the request.
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)
        center.add(request)
    }
}
