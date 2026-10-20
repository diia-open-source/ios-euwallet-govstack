
import UIKit
import ReactiveKit
import DiiaMVPModule
import DiiaCommonTypes
import DiiaUIComponents

public protocol DocumentModel: AnyObject {
    var id: String { get }
    var model: DSDocumentData? { get }
    var orderIdentifier: String { get }
    var docType: DocumentAttributesProtocol? { get }
    var frontView: FrontViewProtocol { get }

    /// Human-readable document type name as provided by the issuer,
    /// e.g. "National ID (mDoc)" or "Driving Licence (mDoc)".
    var displayName: String { get }

    /// The credential issuer identifier (host name) for this document,
    /// e.g. "ec.dev.issuer.eudiw.dev". Used for display in the reordering UI.
    var issuerIdentifier: String? { get }

    func backView(for type: VerificationType?, flippingAction: @escaping Callback) -> FlippableEmbeddedView?

    func sharingRequest() -> Signal<ShareLinkModel, Error>?
    func getCardActions(view: BaseView, flipper: FlipperVerifyProtocol) -> [[Action]]
}

public extension DocumentModel {
    var displayName: String { return model?.docData.docName ?? "" }
    var issuerIdentifier: String? { return nil }
}

public protocol FrontViewProtocol: FlippableEmbeddedView, VerifyDocumentViewProtocol {
    var contextMenuCallback: Callback? { get set }
    func setLoadingState(_ state: DSDocumentState)
    func setErrorDescriptionTrailing(offset: CGFloat)
}

public extension FrontViewProtocol {
    func setLoadingState(_ state: DSDocumentState) {}
    func setErrorDescriptionTrailing(offset: CGFloat) {}
}

// MARK: - Protocols
public protocol FlipperVerifyProtocol: AnyObject {
    func flip(for: VerificationType?)
}

public protocol FlippableEmbeddedView: UIView {
    func willPresent()
    func willHide()
    func didHide()
    func didChangeFocus(isFocused: Bool)
    func changeVerificationView(for verificationType: VerificationType)
}

extension FlippableEmbeddedView {
    public func willPresent() {}
    public func willHide() {}
    public func didHide() {}
    public func didChangeFocus(isFocused: Bool) {}
    public func changeVerificationView(for verificationType: VerificationType) {}
}

// it is required for verification feature, that is not moved into DocumentCore, but VerifyDocumentViewProtocol is used in DocumentModel
public protocol VerifyDocumentViewProtocol: UIView {
    func verifyDocumentViewDidChangeLayout()
}

public extension VerifyDocumentViewProtocol {
    func verifyDocumentViewDidChangeLayout() {}
}
