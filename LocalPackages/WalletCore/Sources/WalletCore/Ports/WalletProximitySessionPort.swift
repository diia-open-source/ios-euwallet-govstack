//
//  WalletProximitySessionPort.swift
//

import Foundation
import WalletDomainModels

/// Categorises proximity-sharing failure modes so the presenter can show the right alert (turn on Bluetooth, grant permission, retry, etc.) without having to interpret raw error strings.
public enum WalletProximityErrorKind {
    case accessRequired
    case turnedOff
    case connectionLost
}

/// Callbacks emitted by an `WalletProximitySessionManaging` instance.
/// Domain-typed everywhere so feature SPMs that conform never import any eudi-* module.
public protocol WalletProximitySessionDelegate: AnyObject {
    func didGenerateQRCode(_ payload: String)
    func didReceiveRequest(_ request: PresentationRequest)
    func didFinishPresentation()
    /// Domain-typed error (not the upstream SDK type) so presenters in `WalletSharing` don't have to import any eudi-* module — keeps WalletCore's wrap boundary intact.
    /// Carries the structured `code` / `context` payload; `WalletErrorFormatter` consumes both.
    func didReceiveError(_ error: PresentationError?, kind: WalletProximityErrorKind?)
}

public extension WalletProximitySessionDelegate {
    func didGenerateQRCode(_ payload: String) {}
    func didReceiveRequest(_ request: PresentationRequest) {}
    func didReceiveError(_ error: PresentationError?, kind: WalletProximityErrorKind?) {}
}

/// Feature-facing protocol for proximity (BLE) credential sharing sessions.
/// The concrete `WalletProximitySessionManager` lives in WalletEngine and imports the SDK directly; features depend on this protocol and obtain instances via `WalletDependencies.proximitySessionFactory()` so they never import WalletEngine.
/// One instance per sharing flow — sessions are not shared across requests.
public protocol WalletProximitySessionManaging: AnyObject {
    var delegate: WalletProximitySessionDelegate? { get set }
    func startProximityPresentation()
    func sendResponse(disclosedItems: SharingDisclosure)
    func cancelPresentation()
}
