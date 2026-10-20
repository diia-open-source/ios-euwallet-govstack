//
//  MdlCardViewModel.swift
//

import UIKit
import ReactiveKit
import DiiaMVPModule
import DiiaCommonTypes
import DiiaUIComponents
import WalletDocumentsCore
import WalletDocumentsCommonTypes
import WalletCore
import WalletDomainModels

final class MdlCardViewModel: DocumentModel {

    // MARK: - Properties
    let model: DSDocumentData?
    let docNumber: String
    private let isRevoked: Bool
    /// Cryptographic expiry resolved by the factory (envelope value if the SDK
    /// supplied one, else the legacy date-only claim parsed at midnight, else
    /// `.distantFuture`). Compared lazily so the badge reflects current time
    /// every render — no stale `Bool` cached on the view model.
    private let validUntil: Date
    /// Invoked when the user taps the "remove revoked" action. The provider
    /// owns the orchestration (SDK delete + revocation-cache clear + storage
    /// refresh + reorder notification) — the view model carries no service
    /// references of its own.
    private let onRemoveRevoked: () -> Void
    /// Invoked when the user taps the "remove expired" action. Same separation
    /// as `onRemoveRevoked`.
    private let onRemoveExpired: () -> Void
    /// Invoked from the explicit "delete" action (post-confirmation). Async-
    /// throwing so the view model can pick the right follow-up alert (success
    /// vs. error). The provider performs the SDK delete + storage refresh +
    /// reorder notification.
    private let onDelete: (String) async throws -> Void
    let issuerIdentifier: String?

    /// The gallery's presenting view, captured when the card's action menu is
    /// built (`getCardActions(view:)`, called on display). Reused to surface the
    /// deletion-confirmation alert when the user taps the inline revoked/expired
    /// remove button, which otherwise carries no view reference of its own.
    private weak var presentingView: BaseView?

    var isExpired: Bool { DocumentExpiryResolver.isExpired(validUntil: validUntil) }

    /// Recomputed each access so the red overlay appears the moment the doc
    /// crosses its expiry (on the next render — there's no internal timer).
    var errorViewModel: DocumentErrorViewModel? {
        if isRevoked { return revokedErrorViewModel }
        if isExpired { return expiredErrorViewModel }
        return nil
    }

    private lazy var revokedErrorViewModel = DocumentErrorViewModel(
        title: WalletStringKey.documentRevokedTitle.localized(),
        description: WalletStringKey.documentRevokedDescription.localized(),
        action: Action(
            title: WalletStringKey.documentRevokedRemoveAction.localized(),
            image: nil,
            callback: { [weak self] in
                guard let self = self else { return }
                self.confirmRemoval(self.onRemoveRevoked)
            }
        )
    )

    private lazy var expiredErrorViewModel = DocumentErrorViewModel(
        title: WalletStringKey.documentExpiredTitle.localized(),
        description: WalletStringKey.documentExpiredDescription.localized(),
        action: Action(
            title: WalletStringKey.documentExpiredDeleteAction.localized(),
            image: nil,
            callback: { [weak self] in
                guard let self = self else { return }
                self.confirmRemoval(self.onRemoveExpired)
            }
        )
    )

    // MARK: - DocumentViewModel
    var id: String { model?.id ?? "" }
    var orderIdentifier: String { model?.id ?? docNumber }
    let docType: DocumentAttributesProtocol? = DocType.mdlDocument

    var displayName: String {
        guard let docTypeStr = model?.docData.docType,
              let walletDocType = WalletDocumentType(rawValue: docTypeStr) else {
            return model?.docData.docName ?? ""
        }
        return walletDocType.displayName
    }
    var images = [DSDocumentContentData: UIImage]()

    lazy var frontView: FrontViewProtocol = {
        let view: DSDocumentWithPhotoView = DSDocumentWithPhotoView()
        let viewModel = DSDocumentWithPhotoViewModel(
            model: model,
            images: images,
            docType: docType,
            errorViewModel: errorViewModel
        )
        view.configure(for: viewModel)
        return view
    }()

    // MARK: - Init
    init(
        data: DSDocumentData,
        isRevoked: Bool = false,
        validUntil: Date = .distantFuture,
        issuerIdentifier: String? = nil,
        onRemoveRevoked: @escaping () -> Void,
        onRemoveExpired: @escaping () -> Void,
        onDelete: @escaping (String) async throws -> Void
    ) {
        self.model = data
        self.docNumber = data.docNumber
        self.isRevoked = isRevoked
        self.validUntil = validUntil
        self.onRemoveRevoked = onRemoveRevoked
        self.onRemoveExpired = onRemoveExpired
        self.onDelete = onDelete
        self.issuerIdentifier = issuerIdentifier
        data.content?.forEach {
            images[$0.code] = UIImage.createWithBase64String($0.image)
        }
    }

    // MARK: - Actions
    func backView(for type: VerificationType?, flippingAction: @escaping Callback) -> FlippableEmbeddedView? {
        return nil
    }
    
    func getCardActions(view: BaseView, flipper: FlipperVerifyProtocol) -> [[Action]] {
        presentingView = view
        return commonActions(view: view)
    }

    func sharingRequest() -> Signal<ShareLinkModel, Error>? {
        return nil
    }

    // MARK: - Private Methods
    private func commonActions(view: BaseView) -> [[Action]] {
        return [[
            Action(
                title: WalletStringKey.documentGeneralFullInformation.localized(),
                image: WalletGalleryConfiguration.images.documentInfo,
                callback: { [weak self, weak view] in
                    guard let self = self, let view = view else { return }
                    self.openDocumentDetails(in: view)
                }),
            Action(
                title: WalletStringKey.documentGeneralRevokeDocument.localized(),
                image: WalletGalleryConfiguration.images.deleteDocument,
                callback: { [weak self, weak view] in
                    guard let self = self, let view = view else { return }
                    self.deleteDocument(in: view)
                })
        ]]
    }
    
    private func openDocumentDetails(in view: BaseView) {
        guard let docData = self.model else { return }
        
        let viewModel = DocumentDetailsCommonViewModel(
            model: docData,
            images: images,
            eventHandler: nil
        )
        view.showChild(module: DocumentDetailsCommonModule(
            with: viewModel,
            viewStateFactory: DocumentDetailsCommonViewStateFactory()
        ))
    }
    
    private func deleteDocument(in view: BaseView, force: Bool = false) {
        guard force else {
            handleTemplate(Constants.confirmDeletionAlert, in: view)
            return
        }

        Task {
            guard let documentId = model?.id, !documentId.isEmpty else {
                await MainActor.run {
                    self.handleTemplate(Constants.deleteErrorAlert, in: view)
                }
                return
            }
            do {
                try await onDelete(documentId)
                await MainActor.run {
                    self.handleTemplate(Constants.deleteSuccessAlert, in: view)
                }
            } catch {
                await MainActor.run {
                    self.handleTemplate(Constants.deleteErrorAlert, in: view)
                }
            }
        }
    }
    
    /// Surfaces the deletion-confirmation alert before running an inline remove
    /// action (revoked/expired), mirroring the menu-delete flow so every
    /// deletion path requires explicit user confirmation. Uses the view
    /// captured in `getCardActions(view:)`; if none was captured (card never
    /// built its action menu) the removal runs directly rather than silently
    /// dropping the user's tap.
    private func confirmRemoval(_ removal: @escaping () -> Void) {
        guard let view = presentingView else {
            removal()
            return
        }
        WalletDependencies.templatePresenter.handle(Constants.confirmDeletionAlert, in: view) { action in
            switch action {
            case .delete:
                removal()
            default:
                break
            }
        }
    }

    private func handleTemplate(_ template: AlertTemplate, in view: BaseView) {
        WalletDependencies.templatePresenter.handle(template, in: view) { [weak self, weak view] action in
            guard let self = self, let view = view else { return }
            switch action {
            case .delete:
                self.deleteDocument(in: view, force: true)
            default:
                break
            }
        }
    }
}

// MARK: - Constants
private extension MdlCardViewModel {
    enum Constants {
        static let confirmDeletionAlert: AlertTemplate = AlertTemplate(
            type: .middleCenterIconBlackButtonAlert,
            isClosable: false,
            data: AlertTemplateData(
                icon: .attentionBlackRound,
                title: WalletStringKey.documentDeleteAlertTitle.localized(),
                description: WalletStringKey.documentDeleteAlertDescription.localized(),
                mainButton: AlertButtonModel(
                    title: WalletStringKey.documentDeleteAlertDeleteAction.localized(),
                    icon: nil,
                    action: .delete),
                alternativeButton: AlertButtonModel(
                    title: WalletStringKey.generalCancel.localized(),
                    icon: nil,
                    action: .cancel)
            )
        )

        static let deleteSuccessAlert: AlertTemplate = AlertTemplate(
            type: .middleCenterIconBlackButtonAlert,
            isClosable: false,
            data: AlertTemplateData(
                icon: .doneBlackRound,
                title: WalletStringKey.documentDeleteSuccessTitle.localized(),
                description: nil,
                mainButton: AlertButtonModel(
                    title: WalletStringKey.generalProblemOk.localized(),
                    icon: nil,
                    action: .ok),
                alternativeButton: nil
            )
        )

        static let deleteErrorAlert: AlertTemplate = AlertTemplate(
            type: .middleCenterIconBlackButtonAlert,
            isClosable: false,
            data: AlertTemplateData(
                icon: .attentionBlackRound,
                title: WalletStringKey.documentDeleteErrorTitle.localized(),
                description: nil,
                mainButton: AlertButtonModel(
                    title: WalletStringKey.generalProblemOk.localized(),
                    icon: nil,
                    action: .ok),
                alternativeButton: nil
            )
        )
    }
}
