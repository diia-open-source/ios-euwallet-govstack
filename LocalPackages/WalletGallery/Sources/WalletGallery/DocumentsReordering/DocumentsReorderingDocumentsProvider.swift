import WalletDocumentsCommonTypes

public struct DocumentsReorderingDocumentsProvider: DocumentsReorderingDocumentsProviderProtocol {
    public init() {}

    public func fetchDocuments() -> [DocumentModel] {
        DocumentsProcessor.instance.allDocuments(actionView: nil).map { $0.getValue() }
    }
}
