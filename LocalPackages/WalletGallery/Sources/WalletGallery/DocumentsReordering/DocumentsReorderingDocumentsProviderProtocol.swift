import WalletDocumentsCommonTypes

public protocol DocumentsReorderingDocumentsProviderProtocol {
    func fetchDocuments() -> [DocumentModel]
}
