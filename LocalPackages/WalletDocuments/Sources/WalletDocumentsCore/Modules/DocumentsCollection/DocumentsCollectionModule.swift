
import UIKit
import ReactiveKit
import DiiaCommonTypes
import DiiaMVPModule
import DiiaUIComponents
import WalletDocumentsCommonTypes

public final class DocumentsCollectionModule: BaseModule {
    private let view: DocumentsCollectionViewController
    private let presenter: DocumentsCollectionPresenter

    public init(
        context: DocumentsCollectionContext,
        viewStateFactory: DocumentsCollectionViewStateFactoryProtocol,
        actionFabric: DocumentActionsFabricProtocol
    ) {
        view = DocumentsCollectionViewController()
        view.actionFabric = actionFabric
        presenter = DocumentsCollectionPresenter(
            context: context,
            view: view,
            viewStateFactory: viewStateFactory
        )
        view.presenter = presenter
    }

    public func viewController() -> UIViewController {
        return view
    }
}
