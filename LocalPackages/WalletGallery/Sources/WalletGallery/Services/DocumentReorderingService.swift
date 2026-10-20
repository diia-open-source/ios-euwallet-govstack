import Foundation
import DiiaCommonTypes
import WalletDocumentsCommonTypes
import WalletDocumentsCore
import WalletAppStorage
import WalletCore
import WalletDomainModels

public final class DocumentReorderingService: DocumentReorderingServiceProtocol {
    public func synchronizeIfNeeded() { }

    public static let shared = DocumentReorderingService(store: StoreHelper.instance)

    private let store: StoreHelperProtocol

    private init(store: StoreHelperProtocol) {
        self.store = store
    }
    
    // MARK: - DocumentReorderingServiceProtocol
    public func docTypesOrder() -> [DocTypeCode] {
        let order: [DocType] = store.getValue(forKey: .docsOrder) ?? DocType.allCardTypes
        // Deduplicate while preserving order — guards against a corrupted stored value
        // that could show the same document type multiple times in the collection.
        var seen = Set<DocType>()
        return order.filter { seen.insert($0).inserted }.map(\.rawValue)
    }

    public func setOrder(order: [DocTypeCode], synchronize: Bool) {
        // Deduplicate input to prevent storing a corrupted order in the first place.
        var seen = Set<String>()
        let deduplicatedOrder = order.filter { seen.insert($0).inserted }
        let newOrder = deduplicatedOrder.compactMap({ DocType(rawValue: $0) })
        let storedOrder = docTypesOrder().compactMap({ DocType(rawValue: $0) })
        guard newOrder != storedOrder else { return }
        store.save(newOrder, type: [DocType].self, forKey: .docsOrder)
        NotificationCenter.default.post(name: DocumentsConstants.Notifications.documentsWasReordered, object: nil)
    }
    
    public func order(for type: DocTypeCode) -> [String] {
        guard let docType = DocType(rawValue: type),
              let docsOrder: [DocType: [String]] = store.getValue(forKey: .docsStackOrder),
              let order = docsOrder[docType]
        else { return [] }
        return order
    }
    
    public func setOrder(order: [String], for type: DocTypeCode) {
        guard let docType = DocType(rawValue: type) else { return }
        var docsOrder: [DocType: [String]] = store.getValue(forKey: .docsStackOrder) ?? [:]
        docsOrder[docType] = order
        store.save(docsOrder, type: [DocType: [String]].self, forKey: .docsStackOrder)
        NotificationCenter.default.post(name: DocumentsConstants.Notifications.documentsWasReordered, object: nil)
    }
    
    // MARK: - Flat document order (addition-time order, cross all types)

    /// Returns the user's saved flat document order as a list of `orderIdentifier` values.
    /// Returns an empty array when no custom order has been saved yet — callers treat
    /// that as "natural addition order" (the order providers return documents).
    public func flatDocumentOrder() -> [String] {
        return store.getValue(forKey: .docsFlatOrder) ?? []
    }

    /// Persists the user's preferred flat document order.
    public func setFlatOrder(order: [String]) {
        let stored = flatDocumentOrder()
        guard order != stored else { return }
        store.save(order, type: [String].self, forKey: .docsFlatOrder)
        NotificationCenter.default.post(name: DocumentsConstants.Notifications.documentsWasReordered, object: nil)
    }

    public func cleanSynchronized(for type: DocTypeCode) {
        guard let docType = DocType(rawValue: type) else { return }
        guard var order: [DocType: [String]] = store.getValue(forKey: .docsStackOrder) else { return }
        order[docType] = nil
        store.save(order, type: [DocType: [String]].self, forKey: .docsStackOrder)
    }
    
    public func updateOrdersIfNeeded() {
        guard let order: [DocType] = store.getValue(forKey: .docsOrder) else { return }
        setOrder(order: order.map(\.rawValue), synchronize: false)
    }
}
