
import Foundation
import DiiaMVPModule
import WalletDocumentsCommonTypes

public protocol DocumentsProvider {
    func documents(with order: [DocTypeCode], actionView: BaseView?) -> [MultiDataType<DocumentModel>]
}
