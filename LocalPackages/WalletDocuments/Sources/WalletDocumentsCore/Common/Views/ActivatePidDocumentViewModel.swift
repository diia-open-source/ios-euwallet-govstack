//
//  ActivatePidDocumentViewModel.swift
//  WalletDocuments
//

import UIKit
import ReactiveKit
import DiiaMVPModule
import DiiaCommonTypes
import DiiaUIComponents
import WalletDocumentsCommonTypes

public class ActivatePidDocumentViewModel: DocumentModel {

    var activateCallback: Callback

    public init(activateCallback: @escaping Callback) {
        self.activateCallback = activateCallback
    }

    // MARK: - DocumentViewModel
    public var id: String { return "" }
    public var orderIdentifier: String { return "" }
    public var model: DSDocumentData?
    public let docType: DocumentAttributesProtocol? = nil
    public var images = [DSDocumentContentData: UIImage]()
    public var errorViewModel: DocumentErrorViewModel?

    public lazy var frontView: FrontViewProtocol = {
        let view = PidActivateCardView()
        view.configure(with: PidActivateCardViewModel(
            image: R.Image.pidActivationImageEnglish.image,
            title: R.Strings.pid_activate_title.localized(),
            description: R.Strings.pid_activate_description.localized(),
            btnStrokeDefaultAtm: DSButtonModel(
                label: R.Strings.pid_activate_button.localized(),
                action: DSActionParameter(type: "open_pid_onboarding")
            ),
            eventHandler: { [weak self] _ in
                self?.activateCallback()
            })
        )
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
