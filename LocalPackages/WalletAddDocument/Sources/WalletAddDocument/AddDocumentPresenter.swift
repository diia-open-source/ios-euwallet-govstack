import Foundation
import DiiaMVPModule
import DiiaUIComponents
import DiiaCommonServices
import WalletDocumentsCore
import WalletCore
import WalletDomainModels

final class AddDocumentPresenter: ConstructorScreenPresenter {
    unowned var view: AddDocumentView

    private let documentTypesLoader: () async throws -> [AvailableDocumentType]
    private let onDocumentSelected: (AvailableDocumentType) -> Void
    private let documentTypeMapper: AddDocumentDocumentTypeMapperProtocol
    private let viewStateFactory: AddDocumentViewStateFactoryProtocol
    private let presentQRScanner: (BaseView) -> Void
    private var documentTypes: [AvailableDocumentType] = []
    private var loadTask: Task<Void, Never>?
    private var hasAppearedOnce = false

    init(view: AddDocumentView,
         documentTypesLoader: @escaping () async throws -> [AvailableDocumentType],
         onDocumentSelected: @escaping (AvailableDocumentType) -> Void,
         documentTypeMapper: AddDocumentDocumentTypeMapperProtocol,
         viewStateFactory: AddDocumentViewStateFactoryProtocol,
         presentQRScanner: @escaping (BaseView) -> Void) {
        self.view = view
        self.documentTypesLoader = documentTypesLoader
        self.onDocumentSelected = onDocumentSelected
        self.documentTypeMapper = documentTypeMapper
        self.viewStateFactory = viewStateFactory
        self.presentQRScanner = presentQRScanner
    }

    func configureView() {
        loadTask?.cancel()
        loadTask = Task { [weak self] in
            guard let self else { return }

            await MainActor.run { [weak self] in
                guard let self else { return }
                self.view.setQRButtonHidden(true)
                self.view.showProgress()
            }

            do {
                let documentTypes = try await self.documentTypesLoader()
                guard !Task.isCancelled else { return }

                await MainActor.run { [weak self] in
                    guard let self else { return }
                    self.documentTypes = documentTypes
                    self.view.setQRButtonHidden(documentTypes.isEmpty)
                    self.view.configure(model: self.viewStateFactory.make(
                        documentTypes: documentTypeMapper.map(documentTypes)
                    ))
                    self.view.hideProgress()
                }
            } catch {
                guard !Task.isCancelled else { return }

                await MainActor.run { [weak self] in
                    guard let self else { return }
                    self.documentTypes = []
                    if ReachabilityHelper.shared.isReachable() {
                        self.view.setQRButtonHidden(true)
                        self.view.configure(model: self.viewStateFactory.make(documentTypes: []))
                        self.view.showError(error: error.localizedDescription)
                    } else {
                        self.view.setQRButtonHidden(true)
                        self.view.configure(model: self.viewStateFactory.make(contentState: .offline))
                    }
                    self.view.hideProgress()
                }
            }
        }
    }

    func onViewAppear() {
        guard hasAppearedOnce else {
            hasAppearedOnce = true
            return
        }

        configureView()
    }

    func handleEvent(event: ConstructorItemEvent) {
        guard let action = event.actionParameters(),
              let screenAction = AddDocumentScreenAction(rawValue: action.type)
        else { return }

        switch screenAction {
        case .back:
            view.closeModule(animated: true)
        case .selectDocument:
            // The action's `resource` is a row key built as "<identifier>|<issuerId>"
            // (see `AddDocumentItemViewData.rowKey`). The composite is necessary because
            // the same `credential_configuration_id` may be published by multiple issuers.
            guard let rowKey = action.resource,
                  let selectedDocumentType = documentTypes.first(where: {
                      "\($0.identifier)|\($0.issuerId)" == rowKey
                  })
            else { return }
            onDocumentSelected(selectedDocumentType)
        case .openScanQR:
            presentQRScanner(view)
        case .retry:
            configureView()
        }
    }
}
