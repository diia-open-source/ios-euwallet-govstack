//
//  PidDocumentProvider.swift
//

import Foundation
import DiiaMVPModule
import DiiaCommonTypes
import WalletDocumentsCommonTypes
import WalletCore
import WalletDomainModels

class PidDocumentProvider: DocumentModelProvider {
    private let walletController: WalletKitProtocol
    private let revocationService: DocumentRevocationService
    private let viewStateFactory: PidDocumentViewStateFactoryProtocol
    private let deferredViewStateFactory: DeferredDocumentViewStateFactoryProtocol
    private var documentEntries: [(model: DSFullDocumentModel, issuerIdentifier: String?)] = []
    private var documentIds: [String] = []
    private var deferredDocuments: [Credential] = []

    let modelKey = WalletDocumentType.pidMdoc.rawValue
    let docCode = DocType.pidDocument.rawValue

    private let pidTypeKeys = WalletDocumentType.allPidTypes.map { $0.rawValue }

    init(
        walletController: WalletKitProtocol,
        revocationService: DocumentRevocationService,
        viewStateFactory: PidDocumentViewStateFactoryProtocol,
        deferredViewStateFactory: DeferredDocumentViewStateFactoryProtocol
    ) {
        self.walletController = walletController
        self.revocationService = revocationService
        self.viewStateFactory = viewStateFactory
        self.deferredViewStateFactory = deferredViewStateFactory
    }

    func saveDocumentsToStorage(documentsResponse: AnyCodable) { }

    func getStoredDocuments(actionView: BaseView?) -> [DocumentModel] {
        loadDocumentFromStorage()
        let issuedCards: [DocumentModel] = documentEntries.flatMap { entry in
            return entry.model.data.map { data in
                let isRevoked = revocationService.isRevoked(documentId: data.id)
                return PidCardViewModel(
                    data: data,
                    isRevoked: isRevoked,
                    validUntil: entry.model.expirationDate,
                    issuerIdentifier: entry.issuerIdentifier,
                    onRemoveRevoked: { [weak self] in self?.removeRevokedDocument(id: data.id) },
                    onRemoveExpired: { [weak self] in self?.removeExpiredDocument(id: data.id) },
                    onDelete: { [weak self] id in
                        guard let self else { return }
                        try await self.deleteDocument(id: id)
                    }
                )
            }
        }
        let deferredCards: [DocumentModel] = deferredDocuments.compactMap { doc -> DocumentModel? in
            let fullModel = deferredViewStateFactory.make(credential: doc)
            guard let data = fullModel.data.first else { return nil }
            return DeferredDocumentViewModel(
                data: data,
                issuerIdentifier: doc.credentialIssuerIdentifier,
                docType: DocType.pidDocument,
                providerType: docCode
            )
        }
        return issuedCards + deferredCards
    }

    func refreshFromStorage() {
        documentIds = []
        documentEntries = []
        deferredDocuments = []
        loadDocumentFromStorage()
    }

    func cleanStorage() {
        documentIds = []
        documentEntries = []
        deferredDocuments = []
    }
        
    func needRemoteUpdates() -> Bool {
        return false
    }

    // MARK: - Removal

    /// Removes a revoked PID document from the SDK store, clears the
    /// revocation cache (so the badge re-evaluates from scratch), and refreshes
    /// this provider's storage + posts the reorder notification so the UI
    /// reacts. Called from the card view-model's revoked-action callback —
    /// the view model itself carries no service references.
    func removeRevokedDocument(id: String) {
        Task {
            do {
                try await walletController.deleteDocument(with: id)
                await MainActor.run {
                    self.revocationService.clearCache()
                    DocumentsProcessor.instance.refreshDocumentFromStorage(type: self.docCode)
                    NotificationCenter.default.post(name: DocumentsConstants.Notifications.documentsWasReordered, object: nil)
                }
            } catch { }
        }
    }

    /// Removes an expired PID document. Mirrors `removeRevokedDocument(id:)`
    /// but skips the revocation-cache clear — expiry is a local clock check,
    /// not a server-side revocation status.
    func removeExpiredDocument(id: String) {
        Task {
            do {
                try await walletController.deleteDocument(with: id)
                await MainActor.run {
                    DocumentsProcessor.instance.refreshDocumentFromStorage(type: self.docCode)
                    NotificationCenter.default.post(name: DocumentsConstants.Notifications.documentsWasReordered, object: nil)
                }
            } catch { }
        }
    }

    /// User-initiated delete (from the card's action menu, post-confirmation).
    /// Async-throwing so the view model can present success/error alerts. Same
    /// orchestration as `removeExpiredDocument(id:)` — SDK delete + provider
    /// refresh + reorder notification — but the throw escapes for UI handling.
    func deleteDocument(id: String) async throws {
        try await walletController.deleteDocument(with: id)
        await MainActor.run {
            DocumentsProcessor.instance.refreshDocumentFromStorage(type: self.docCode)
            NotificationCenter.default.post(name: DocumentsConstants.Notifications.documentsWasReordered, object: nil)
        }
    }

    // MARK: - Private Methods
    private func loadDocumentFromStorage() {
        deferredDocuments = walletController.fetchDeferredDocuments()
            .filter { pidTypeKeys.contains($0.docType) }

        guard !walletController.isStorageEmpty else {
            documentEntries = []
            documentIds = []
            return
        }

        let allPidDocuments = pidTypeKeys.flatMap { walletController.fetchDocuments(with: $0) }

        guard !allPidDocuments.isEmpty else {
            documentEntries = []
            documentIds = []
            return
        }
        let newDocumentIds = allPidDocuments.map(\.id)
        guard documentIds != newDocumentIds else {
            return
        }

        documentIds = newDocumentIds
        documentEntries = allPidDocuments.map { doc in
            (
                model: viewStateFactory.make(document: PidDocumentModel(doc)),
                issuerIdentifier: doc.credentialIssuerIdentifier
            )
        }
    }
}
