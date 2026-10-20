import UIKit
import DiiaMVPModule
import WalletDocumentsCore
import DiiaUIComponents
       
public final class DocumentsReorderingModule: BaseModule {
    private let view: ConstructorViewController
    private let presenter: DocumentsReorderingPresenter

    public init(
        orderService: DocumentReorderingServiceProtocol,
        documentsProvider: DocumentsReorderingDocumentsProviderProtocol,
        viewStateFactory: DocumentsReorderingViewStateFactoryProtocol,
        backgroundImage: UIImage? = nil
    ) {
        view = ConstructorViewController()
        let fabric = DSViewFabric()
        fabric.setBuilder(DocumentsReorderingListBuilder())
        view.setFabric(fabric)
        presenter = DocumentsReorderingPresenter(
            view: view,
            orderService: orderService,
            documentsProvider: documentsProvider,
            viewStateFactory: viewStateFactory,
            backgroundImage: backgroundImage
        )
        view.presenter = presenter
    }

    public func viewController() -> UIViewController {
        return view
    }
}
