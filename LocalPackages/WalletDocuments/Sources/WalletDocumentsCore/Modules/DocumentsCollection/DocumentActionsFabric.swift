
import Foundation
import DiiaMVPModule
import DiiaCommonTypes
import WalletDocumentsCommonTypes

public protocol DocumentActionsFabricProtocol {
    func getAction(for dataType: MultiDataType<DocumentModel>, view: BaseView, flipper: FlipperVerifyProtocol) -> Callback?
}

public struct DocumentActionsFabric: DocumentActionsFabricProtocol {

    public init() {}

    public func getAction(for dataType: MultiDataType<DocumentModel>, view: BaseView, flipper: FlipperVerifyProtocol) -> Callback? {
        guard case let .single(document) = dataType else { return nil }
        let actions = document.getCardActions(view: view, flipper: flipper)

        guard !actions.isEmpty else { return nil }
        return { [weak view] in
            guard let view else { return }
            view.showChild(module: DocumentActionSheetModule(actions: actions))
        }
    }
}
