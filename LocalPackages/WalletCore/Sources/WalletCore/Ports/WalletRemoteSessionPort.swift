//
//  WalletRemoteSessionPort.swift
//

import Foundation
import WalletDomainModels

/// Callbacks emitted by an `WalletRemoteSessionManaging` instance.
/// Domain-typed everywhere so feature SPMs that conform never import any eudi-* module.
public protocol WalletRemoteSessionDelegate: AnyObject {
    func didFinishPresentation(with redirectUrl: String?)
    func didReceiveRequest(_ request: PresentationRequest)
    /// Domain-typed error (not the upstream SDK type) so presenters in `WalletSharing` don't have to import any eudi-* module — keeps WalletCore's wrap boundary intact.
    /// Carries the structured `code` / `context` payload; `WalletErrorFormatter` consumes both.
    func didReceiveError(_ error: PresentationError?)
}

/// Feature-facing protocol for remote (OID4VP) credential sharing sessions.
/// The concrete `WalletRemoteSessionManager` lives in WalletEngine and imports the SDK directly; features depend on this protocol and obtain instances via `WalletDependencies.remoteSessionFactory()` so they never import WalletEngine.
/// One instance per sharing flow — sessions are not shared across requests.
public protocol WalletRemoteSessionManaging: AnyObject {
    var delegate: WalletRemoteSessionDelegate? { get set }
    func startRemotePresentation(urlString: String)
    func sendResponse(disclosedItems: SharingDisclosure)
    func cancelPresentation()
}
