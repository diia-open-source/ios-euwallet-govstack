import UIKit
import DiiaMVPModule
import WalletDocumentsCommonTypes
import WalletDocumentsCore
import DiiaUIComponents

final class DocumentsReorderingPresenter: ConstructorScreenPresenter {
    unowned var view: ConstructorScreenViewProtocol
    private let orderService: DocumentReorderingServiceProtocol
    private let documentsProvider: DocumentsReorderingDocumentsProviderProtocol
    private let viewStateFactory: DocumentsReorderingViewStateFactoryProtocol
    private let backgroundImage: UIImage?

    private var documents: [DocumentModel]

    // MARK: - Init
    init(
        view: ConstructorScreenViewProtocol,
        orderService: DocumentReorderingServiceProtocol,
        documentsProvider: DocumentsReorderingDocumentsProviderProtocol,
        viewStateFactory: DocumentsReorderingViewStateFactoryProtocol,
        backgroundImage: UIImage?
    ) {
        self.view = view
        self.orderService = orderService
        self.documentsProvider = documentsProvider
        self.viewStateFactory = viewStateFactory
        self.backgroundImage = backgroundImage
        self.documents = documentsProvider.fetchDocuments()
    }

    func configureView() {
        if let backgroundImage {
            view.setupBackground(.image(backgroundImage))
        }
        view.configure(model: viewStateFactory.make(documents: documents))
    }

    private func moveItem(from index: Int, toIndex: Int) {
        let item = documents.remove(at: index)
        documents.insert(item, at: toIndex)
    }

    func handleEvent(event: ConstructorItemEvent) {
        if case .customEvent(let customEvent) = event,
           customEvent.code == DocumentsReorderingCustomEventCode.moveItem.rawValue,
           let fromIndex = customEvent.payload[DocumentsReorderingCustomEventPayload.fromIndex] as? Int,
           let toIndex = customEvent.payload[DocumentsReorderingCustomEventPayload.toIndex] as? Int {
            moveItem(from: fromIndex, toIndex: toIndex)
            saveDocumentsInOrder()
            return
        }

        guard let action = event.actionParameters(),
              let screenAction = DocumentsReorderingScreenAction(rawValue: action.type) else { return }

        switch screenAction {
        case .back:
            view.closeModule(animated: true)
        }
    }

    // MARK: - Private Methods
    private func saveDocumentsInOrder() {
        let order = documents.map { $0.orderIdentifier }
        orderService.setFlatOrder(order: order)
    }
}
