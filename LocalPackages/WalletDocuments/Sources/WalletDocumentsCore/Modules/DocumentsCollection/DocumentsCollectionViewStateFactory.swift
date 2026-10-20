//
//  DocumentsCollectionViewStateFactory.swift
//

import Foundation
import DiiaCommonTypes
import WalletDocumentsCommonTypes

public struct DocumentsCollectionViewState {
    public let documents: [MultiDataType<DocumentModel>]
    public let isQRPlaceholderVisible: Bool

    public init(
        documents: [MultiDataType<DocumentModel>],
        isQRPlaceholderVisible: Bool
    ) {
        self.documents = documents
        self.isQRPlaceholderVisible = isQRPlaceholderVisible
    }
}

public protocol DocumentsCollectionViewStateFactoryProtocol {
    func make(
        documents: [MultiDataType<DocumentModel>],
        activateCardProvider: () -> DocumentModel,
        addCardProvider: () -> DocumentModel?
    ) -> DocumentsCollectionViewState
}

public struct DocumentsCollectionViewStateFactory: DocumentsCollectionViewStateFactoryProtocol {

    public init() {}

    public func make(
        documents: [MultiDataType<DocumentModel>],
        activateCardProvider: () -> DocumentModel,
        addCardProvider: () -> DocumentModel?
    ) -> DocumentsCollectionViewState {
        let isQRPlaceholderVisible = !documents.isEmpty
        var list = documents

        if documents.isEmpty {
            list.append(.single(activateCardProvider()))
        } else if let addCard = addCardProvider() {
            list.append(.single(addCard))
        }

        return DocumentsCollectionViewState(
            documents: list,
            isQRPlaceholderVisible: isQRPlaceholderVisible
        )
    }
}
