
import UIKit
import ReactiveKit
import DiiaCommonTypes
import DiiaMVPModule
import DiiaUIComponents
import WalletDocumentsCommonTypes

public final class AddNewDocumentViewModel: DocumentModel {

    var addDocumentCallback: Callback
    var changeOrderCallback: Callback

    public init(addDocumentCallback: @escaping Callback,
                changeOrderCallback: @escaping Callback) {
        self.addDocumentCallback = addDocumentCallback
        self.changeOrderCallback = changeOrderCallback
    }

    // MARK: - DocumentViewModel
    public var id: String { return "" }
    public var orderIdentifier: String { return "" }
    public var model: DSDocumentData?
    public let docType: DocumentAttributesProtocol? = nil
    public var images = [DSDocumentContentData: UIImage]()
    public var errorViewModel: DocumentErrorViewModel?

    public lazy var frontView: FrontViewProtocol = {
        let view: AddNewDocumentView = AddNewDocumentView.fromNib(bundle: Bundle.module)
        view.configure(addDocumentCallback: addDocumentCallback,
                       changeOrderCallback: changeOrderCallback)
        return view
    }()

    public func backView(for type: VerificationType?, flippingAction: @escaping Callback) -> FlippableEmbeddedView? {
        return nil
    }

    public func sharingRequest() -> Signal<ShareLinkModel, Error>? {
        return nil
    }

    public func getCardActions(view: BaseView, flipper: FlipperVerifyProtocol) -> [[Action]] {
        return []
    }
}
