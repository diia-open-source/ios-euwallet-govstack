import UIKit
import DiiaMVPModule
import WalletDocumentsCore
import DiiaUIComponents
import WalletCore
import WalletDomainModels

public final class AddDocumentModule: BaseModule {
    private let view: AddDocumentViewController
    private let presenter: AddDocumentPresenter

    public init(
        documentTypesLoader: @escaping () async throws -> [AvailableDocumentType],
        onDocumentSelected: @escaping (AvailableDocumentType) -> Void,
        documentTypeMapper: AddDocumentDocumentTypeMapperProtocol,
        viewStateFactory: AddDocumentViewStateFactoryProtocol,
        presentQRScanner: @escaping (BaseView) -> Void,
        qrButtonImage: UIImage? = nil
    ) {
        view = AddDocumentViewController()
        view.qrButtonImage = qrButtonImage
        presenter = AddDocumentPresenter(
            view: view,
            documentTypesLoader: documentTypesLoader,
            onDocumentSelected: onDocumentSelected,
            documentTypeMapper: documentTypeMapper,
            viewStateFactory: viewStateFactory,
            presentQRScanner: presentQRScanner
        )
        view.presenter = presenter
    }

    public func viewController() -> UIViewController {
        return view
    }
}
