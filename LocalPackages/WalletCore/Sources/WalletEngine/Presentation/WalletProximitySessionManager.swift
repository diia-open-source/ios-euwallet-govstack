//
//  WalletProximitySessionManager.swift
//

import Combine
import WalletCore
import WalletDomainModels
import CoreBluetooth
import Foundation
import EudiWalletKit
import MdocDataTransfer18013

public final class WalletProximitySessionManager: WalletProximitySessionManaging {
    private let walletKitController = WalletKitController.instance
    private var session: PresentationSession?
    private var cancellables = Set<AnyCancellable>()
    private var engagementTask: Task<Void, Never>?
    private var successWorkItem: DispatchWorkItem?
    private var lastBluetoothState: CBManagerState?
    private var lastError: WalletError?
    private var didCompleteWithError = false
    private var isStartingPresentation = false
    private var hasPresentedEngagement = false

    public weak var delegate: WalletProximitySessionDelegate?

    public init() {}

    // MARK: - Public Methods
    public func startProximityPresentation() {
        guard !isStartingPresentation else { return }
        isStartingPresentation = true
        didCompleteWithError = false
        hasPresentedEngagement = false
        Task { [weak self] in
            guard let self else { return }
            if let bluetoothErrorKind = await self.bluetoothErrorKindBeforeStarting() {
                await MainActor.run {
                    self.failPresentation(kind: bluetoothErrorKind)
                }
                return
            }
            if self.walletKitController.isStorageEmpty {
                try? await self.walletKitController.loadDocuments()
            }
            // Wallet policy forbids sharing an expired or revoked/suspended document, and proximity can only present mDocs.
            // The SDK's own gate fails with `.noDocumentsAvailable` only when the wallet holds no mDoc at all, so it would still generate a QR when the sole mDoc is expired or revoked.
            // Short-circuit here so the QR screen shows the dedicated "no documents available" alert instead of engaging a verifier the wallet could never satisfy.
            guard self.hasShareableMdoc() else {
                await MainActor.run { self.failWithNoShareableDocuments() }
                return
            }
            self.session = await self.walletKitController.startProximityPresentation()
            self.observePresentation()
        }
    }
    
    public func sendResponse(disclosedItems: SharingDisclosure) {
        let upstreamItems = disclosedItems.toUpstreamRequestItems()
        Task { [weak session] in
            guard let session else { return }
            try? await session.sendResponse(userAccepted: true, itemsToSend: upstreamItems)
        }
    }

    public func cancelPresentation() {
        isStartingPresentation = false
        engagementTask?.cancel()
        engagementTask = nil
        successWorkItem?.cancel()
        successWorkItem = nil
        cancellables.removeAll()
        session = nil
    }
    
    // MARK: - Private Methods
    private func observePresentation() {
        session?.$uiError.compactMap { $0 }.sink { [weak self] walletError in
            self?.lastError = walletError
        }.store(in: &cancellables)

        session?.$status.sink { [weak self] status in
            self?.handleStatusChange(status)
        }.store(in: &cancellables)
    }

    private func handleStatusChange(_ status: TransferStatus) {
        switch status {
        case .initializing:
            engagementTask?.cancel()
            engagementTask = Task { [weak self] in await self?.handleInitializing() }
        case .qrEngagementReady:
            notifyQRReady()
        case .requestReceived:
            handleRequestReceived()
        case .responseSent:
            scheduleSuccessPresentation()
        case .disconnected, .error:
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.successWorkItem?.cancel()
                self.successWorkItem = nil
                let walletError = self.lastError ?? self.session?.uiError
                self.failPresentation(error: walletError)
            }
        default:
            break
        }
    }

    private func notifyQRReady() {
        guard let imageData = session?.deviceEngagement, !imageData.isEmpty else {
            // TODO: Update after SDK fix.
            // SDK may report qrEngagementReady even when BLE is unauthorized — treat empty engagement as error
            let walletError = session?.uiError
                ?? WalletError(description: WalletStringKey.sharingBluetoothRequiredForProximity.localized())
            DispatchQueue.main.async { [weak self] in
                self?.failPresentation(
                    error: walletError,
                    kind: self?.currentBluetoothErrorKind()
                )
            }
            return
        }

        hasPresentedEngagement = true
        DispatchQueue.main.async { [weak self] in
            self?.delegate?.didGenerateQRCode(imageData)
        }
    }
    
    private func handleInitializing() async {
        guard let session else { return }
        do {
            try await session.startQrEngagement()
            _ = await session.receiveRequest()
        } catch {
            // `startQrEngagement` may throw a non-`WalletError`; wrap as a plain-described WalletError so the delegate sees a uniform shape.
            // No structured code is available for this path; presenters fall back to the description.
            let walletError = (error as? WalletError)
                ?? WalletError(description: error.localizedDescription)
            await MainActor.run {
                failPresentation(
                    error: walletError,
                    kind: currentBluetoothErrorKind()
                )
            }
        }
    }
    
    private func handleRequestReceived() {
        guard let session, !session.disclosedDocuments.isEmpty else { return }
        // Block only on an explicit validation failure.
        // `nil` means the SDK's session-level reader-auth fields aren't populated for this request — either the verifier didn't include parseable reader auth (matches ISO 18013-5: reader auth is optional), or the per-doctype reader-auth results didn't surface a parseable certificate issuer, which gates assignment to the legacy session-level `readerCertIssuer*` fields.
        //
        // TODO: When the EUDI verifier ecosystem deploys signed reader-auth widely (e.g. eudi-app-multiplatform-verifier-ui starts populating `readerAuthCertificate` instead of null), reconsider switching this gate to strict mode `session.readerCertIssuerValid == true` to require all verifiers to identify themselves.
        // Until then, lenient mode prevents false-blocking spec-compliant verifiers that omit reader auth.
        let isTrusted = session.readerCertIssuerValid != false
        let request = PresentationRequest(
            items: session.disclosedDocuments.map { $0.toDomainRequestedDocument() },
            relyingParty: session.readerCertIssuer ?? WalletStringKey.sharingDefaultRelyingParty.localized(),
            dataRequestInfo: session.readerCertValidationMessage ?? WalletStringKey.sharingDefaultDataRequestInfo.localized(),
            isTrusted: isTrusted
        )
        DispatchQueue.main.async { [weak self] in
            self?.delegate?.didReceiveRequest(request)
        }
    }

    private func scheduleSuccessPresentation() {
        successWorkItem?.cancel()

        let workItem = DispatchWorkItem { [weak self] in
            self?.handleResponseSent()
        }
        successWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.successDelay, execute: workItem)
    }
    
    private func handleResponseSent() {
        isStartingPresentation = false
        engagementTask?.cancel()
        engagementTask = nil
        successWorkItem?.cancel()
        successWorkItem = nil
        cancellables.removeAll()
        session = nil
        DispatchQueue.main.async { [weak self] in
            self?.delegate?.didFinishPresentation()
        }
    }

    private func failPresentation(
        error: WalletError? = nil,
        kind: WalletProximityErrorKind? = nil
    ) {
        // Convert at the boundary so the upstream `WalletError` symbol never leaves WalletCore.
        failPresentation(domainError: error?.toDomainPresentationError(), kind: kind)
    }

    /// Tear down the session and hand the delegate an already-domain `PresentationError`.
    /// Used by gates that decide the presentation can't proceed without an upstream SDK error to convert — e.g. the pre-QR validity gate.
    private func failPresentation(
        domainError: PresentationError?,
        kind: WalletProximityErrorKind? = nil
    ) {
        guard !didCompleteWithError else { return }
        didCompleteWithError = true
        isStartingPresentation = false
        engagementTask?.cancel()
        engagementTask = nil
        successWorkItem?.cancel()
        successWorkItem = nil
        cancellables.removeAll()
        session = nil
        let resolvedKind = kind ?? currentBluetoothErrorKind() ?? (hasPresentedEngagement ? .connectionLost : nil)
        delegate?.didReceiveError(domainError, kind: resolvedKind)
    }

    /// Pre-QR gate: does the wallet hold at least one mDoc that may actually be presented over proximity right now?
    ///
    /// Proximity (ISO 18013-5 BLE) can only present mDoc-format credentials, and wallet policy forbids sharing an expired or revoked/suspended document.
    /// Revocation/suspension is read from `DocumentRevocationService`'s cache — the same source the post-request disclosure screen consults — so the two gates agree.
    /// Returns `false` when no issued mDoc clears both checks, so the caller short-circuits before generating device engagement.
    private func hasShareableMdoc() -> Bool {
        let revocationService = WalletDependencies.walletLifecycle.revocationService
        let now = Date()
        return walletKitController.fetchAllDocuments().contains { credential in
            credential.format == .msoMdoc
                && credential.status == .issued
                && !credential.isExpired(asOf: now)
                && !revocationService.isRevoked(documentId: credential.id)
        }
    }

    /// Deliver the `.noDocumentsAvailable` outcome for the pre-QR validity gate.
    /// `DocumentsQRPresenter` maps this code to the dedicated "no documents available for sharing" alert — the same surface the SDK's own presence check produces when the wallet holds no mDoc.
    private func failWithNoShareableDocuments() {
        failPresentation(domainError: PresentationError(description: nil, code: .noDocumentsAvailable))
    }

    private func bluetoothErrorKindBeforeStarting() async -> WalletProximityErrorKind? {
        switch CBManager.authorization {
        case .denied, .restricted:
            return .accessRequired
        case .allowedAlways, .notDetermined:
            let state = await BluetoothStateReader().readState()
            lastBluetoothState = state
            return Self.errorKind(for: state)
        @unknown default:
            return nil
        }
    }

    private func currentBluetoothErrorKind() -> WalletProximityErrorKind? {
        switch CBManager.authorization {
        case .denied, .restricted:
            return .accessRequired
        default:
            return Self.errorKind(for: lastBluetoothState)
        }
    }

    private static func errorKind(for state: CBManagerState?) -> WalletProximityErrorKind? {
        switch state {
        case .poweredOff:
            return .turnedOff
        case .unauthorized:
            return .accessRequired
        default:
            return nil
        }
    }
}

private extension WalletProximitySessionManager {
    enum Constants {
        static let successDelay: TimeInterval = 0.75
    }
}

private final class BluetoothStateReader: NSObject, CBCentralManagerDelegate {
    private var continuation: CheckedContinuation<CBManagerState, Never>?
    private var centralManager: CBCentralManager?

    private(set) var state: CBManagerState?

    func readState() async -> CBManagerState {
        await withCheckedContinuation { continuation in
            self.continuation = continuation
            centralManager = CBCentralManager(
                delegate: self,
                queue: nil,
                options: [CBCentralManagerOptionShowPowerAlertKey: false]
            )
        }
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        state = central.state
        continuation?.resume(returning: central.state)
        continuation = nil
    }
}
