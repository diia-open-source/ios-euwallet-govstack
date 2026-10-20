import Foundation
import DiiaMVPModule
import DiiaCommonTypes
import WalletDocumentsCommonTypes
import WalletDocumentsCore
import WalletCore
import WalletDomainModels

public final class DocumentsProcessor {
    /// Composition-root-configured shared instance. Set by `bootstrap(...)` from
    /// `AppConfigurator` once the wallet's `DocumentRevocationService` instance
    /// has been built. Force-unwrapped on read because nothing in the app
    /// should reach `DocumentsProcessor` before bootstrap — if it does, we'd
    /// rather crash loudly at launch than silently read a stale default.
    public static var instance: DocumentsProcessor!

    /// Wire the shared instance with the host's `DocumentRevocationService`.
    /// Idempotent — safe to call once at app launch; subsequent calls replace
    /// the instance (useful only for testing).
    public static func bootstrap(
        revocationService: DocumentRevocationService,
        walletController: WalletKitProtocol = WalletDependencies.walletController
    ) {
        instance = DocumentsProcessor(documentProviders: [
            PidDocumentProvider(
                walletController: walletController,
                revocationService: revocationService,
                viewStateFactory: PidDocumentViewStateFactory(),
                deferredViewStateFactory: DeferredDocumentViewStateFactory()
            ),
            MdlDocumentProvider(
                walletController: walletController,
                revocationService: revocationService,
                viewStateFactory: MdlDocumentViewStateFactory(),
                deferredViewStateFactory: DeferredDocumentViewStateFactory()
            )
        ])
    }

    let documentsProviders: [String: DocumentModelProvider]
    // Preserves the original provider registration order so that `allDocuments()`
    // produces a stable default when no custom flat order has been saved yet.
    private let orderedProviders: [DocumentModelProvider]

    init(documentProviders: [DocumentModelProvider]) {
        self.orderedProviders = documentProviders
        self.documentsProviders = Dictionary(documentProviders.map { ($0.docCode, $0) }) { _, last in last }
        documentProviders.forEach { $0.migrateIfNeeded() }
    }

    /// Returns all documents from all providers as a flat list.
    /// When the user has saved a custom order, that order is applied;
    /// otherwise documents appear in the natural addition order returned by each provider.
    public func allDocuments(actionView: BaseView?) -> [MultiDataType<DocumentModel>] {
        let orderIds = DocumentReorderingService.shared.flatDocumentOrder()
        let flat = orderedProviders.flatMap { $0.getStoredDocuments(actionView: actionView) }
        return reorderFlat(documents: flat, orderIds: orderIds).map { .single($0) }
    }

    public func documents(with order: [DocTypeCode], actionView: BaseView?) -> [MultiDataType<DocumentModel>] {
        var allDocuments: [MultiDataType<DocumentModel>] = []
        for docCode in order {
            if let docProvider = documentsProviders[docCode] {
                let docs = reorderIfNeeded(
                    documents: docProvider.getStoredDocuments(actionView: actionView),
                    orderIds: DocumentReorderingService.shared.order(for: docCode))
                allDocuments.append(contentsOf: docs.map { .single($0) })
            }
        }

        return allDocuments
    }

    public func refreshDocumentFromStorage(type: DocTypeCode) {
        documentsProviders[type]?.refreshFromStorage()
    }

    /// Refreshes every registered provider's storage. Used by the app's
    /// `WalletDocumentsRefreshing` adapter after a wallet-package mutation lands.
    public func refreshAllFromStorage() {
        documentsProviders.values.forEach { $0.refreshFromStorage() }
    }

    /// Drops every provider's in-memory state. Used by the app's auth flow on logout.
    public func cleanAllProvidersStorage() {
        documentsProviders.values.forEach { $0.cleanStorage() }
    }
    
    private func reorderFlat(documents: [DocumentModel], orderIds: [String]) -> [DocumentModel] {
        guard !orderIds.isEmpty else { return documents }
        var result = documents
        for id in orderIds.reversed() {
            if let index = result.firstIndex(where: { $0.orderIdentifier == id }) {
                let doc = result.remove(at: index)
                result.insert(doc, at: 0)
            }
        }
        return result
    }

    private func reorderIfNeeded(documents: [DocumentModel], orderIds: [String]) -> [DocumentModel] {
        if !orderIds.isEmpty {
            var newDocs = documents
            for id in orderIds.reversed() {
                if let index = newDocs.firstIndex(where: { $0.orderIdentifier == id }) {
                    let document = newDocs.remove(at: index)
                    newDocs.insert(document, at: 0)
                }
            }
            return newDocs
        }
        return documents
    }
}

extension DocumentsProcessor: DocumentsProvider { }
