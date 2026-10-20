//
//  WalletRemoteSessionManager.swift
//

import Combine
import WalletCore
import WalletDomainModels
import Foundation
import EudiWalletKit
import MdocDataTransfer18013

public final class WalletRemoteSessionManager: WalletRemoteSessionManaging {
    public init() {}
    private let walletKitController = WalletKitController.instance
    private var session: PresentationSession?
    private var cancellables = Set<AnyCancellable>()
    private var didComplete = false

    public weak var delegate: WalletRemoteSessionDelegate?

    // MARK: - Public Methods
    public func startRemotePresentation(urlString: String) {
        didComplete = false
        Task { [weak self] in
            guard let self else { return }
            let session = await self.walletKitController.startRemotePresentation(urlString: urlString)
            guard !self.didComplete else { return }
            self.session = session
            self.observeRemotePresentation()
        }
    }

    public func sendResponse(disclosedItems: SharingDisclosure) {
        let upstreamItems = disclosedItems.toUpstreamRequestItems()
        Task { [weak self, weak session] in
            guard let self = self, let session = session else { return }
            try? await session.sendResponse(
                userAccepted: true,
                itemsToSend: upstreamItems,
                onCancel: nil
            ) { [weak self] redirectUrl in
                self?.deliverFinish(redirectUrl: redirectUrl?.absoluteString)
            }
        }
    }

    public func cancelPresentation() {
        didComplete = true
        cancellables.removeAll()
        session = nil
    }

    // MARK: - Private Methods
    private func observeRemotePresentation() {
        // Observe uiError to capture the SDK error (structured code + context, not just description)
        session?.$uiError.compactMap { $0 }.sink { [weak self] walletError in
            self?.lastError = walletError
        }.store(in: &cancellables)

        session?.$status.sink { [weak self] status in
            self?.handleStatusChange(status)
        }.store(in: &cancellables)
    }

    /// Stores the last error from the SDK's uiError publisher,
    /// because uiError may be set after status changes to .error
    private var lastError: WalletError?

    private func handleStatusChange(_ status: TransferStatus) {
        switch status {
        case .initializing:
            handleInitializing()
        case .requestReceived:
            handleRequestReceived()
        case .disconnected, .error:
            // Defer reading to let SDK finish setting uiError on the same run loop
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                let walletError = self.lastError ?? self.session?.uiError
                self.deliverError(walletError?.toDomainPresentationError())
            }
        default:
            break
        }
    }

    private func handleInitializing() {
        Task { [weak session] in
            _ = await session?.receiveRequest()
        }
    }

    private func handleRequestReceived() {
        guard let session, !session.disclosedDocuments.isEmpty else {
            let domainError = session?.uiError?.toDomainPresentationError()
            DispatchQueue.main.async { [weak self] in
                self?.deliverError(domainError)
            }
            return
        }
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

    private func deliverError(_ error: PresentationError?) {
        guard !didComplete else { return }
        didComplete = true
        cancellables.removeAll()
        session = nil
        delegate?.didReceiveError(error)
    }

    private func deliverFinish(redirectUrl: String?) {
        DispatchQueue.main.async { [weak self] in
            guard let self, !self.didComplete else { return }
            self.didComplete = true
            self.delegate?.didFinishPresentation(with: redirectUrl)
        }
    }
}
