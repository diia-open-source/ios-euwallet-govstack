//
//  DocumentModelProvider.swift
//

import Foundation
import DiiaMVPModule
import DiiaCommonTypes
import WalletDocumentsCore
import WalletDocumentsCommonTypes
import WalletAppStorage

protocol DocumentModelProvider {
    func saveDocumentsToStorage(documentsResponse: AnyCodable)
    func getStoredDocuments(actionView: BaseView?) -> [DocumentModel]
    func cleanStorage()
    func refreshFromStorage()
    func migrateIfNeeded()
    func needRemoteUpdates() -> Bool
    func updateLocallyIfNeeded() -> Bool
    var docCode: String { get }
}

extension DocumentModelProvider {
    func saveDoc<T>(_ doc: T?, type: T.Type, forKey key: StoringKey, storeHelper: StoreHelperProtocol, orderService: DocumentReorderingServiceProtocol?) where T: Codable & StatusedExpirableProtocol { }

    func migrateIfNeeded() {}
    func updateLocallyIfNeeded() -> Bool {
        return false
    }
}
