
import Foundation
import WalletDocumentsCommonTypes

public protocol DocumentReorderingServiceProtocol {
    func docTypesOrder() -> [DocTypeCode]
    func setOrder(order: [DocTypeCode], synchronize: Bool)
    func order(for type: DocTypeCode) -> [String]
    func setOrder(order: [String], for type: DocTypeCode)
    func flatDocumentOrder() -> [String]
    func setFlatOrder(order: [String])
    func synchronizeIfNeeded()
    func cleanSynchronized(for type: DocTypeCode)
    func updateOrdersIfNeeded()
}
