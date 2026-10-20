//
//  DeferredDocumentViewModel.swift
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

/// `DocumentModel` for a deferred (pending) credential.
/// Reuses the same `DSDocumentWithPhotoView` chrome as issued PID / MDL cards — the deferred state is expressed entirely through the data shape produced by `DeferredDocumentViewStateFactory` (no claim image, "Pending" footer).
final class DeferredDocumentViewModel: DocumentModel {
    let model: DSDocumentData?
    let docType: DocumentAttributesProtocol?
    let issuerIdentifier: String?
    private let providerType: String

    var id: String { model?.id ?? "" }
    var orderIdentifier: String { id }

    var displayName: String { model?.docData.docName ?? "" }
    var images = [DSDocumentContentData: UIImage]()

    lazy var frontView: FrontViewProtocol = {
        let view = DSDocumentWithPhotoView()
        let viewModel = DSDocumentWithPhotoViewModel(
            model: model,
            images: images,
            docType: docType,
            errorViewModel: nil
        )
        view.configure(for: viewModel)
        return view
    }()

    init(
        data: DSDocumentData,
        issuerIdentifier: String?,
        docType: DocumentAttributesProtocol,
        providerType: String
    ) {
        self.model = data
        self.docType = docType
        self.issuerIdentifier = issuerIdentifier
        self.providerType = providerType
    }

    func backView(for type: VerificationType?, flippingAction: @escaping Callback) -> FlippableEmbeddedView? {
        return nil
    }

    func sharingRequest() -> Signal<ShareLinkModel, Error>? {
        return nil
    }

    func getCardActions(view: BaseView, flipper: FlipperVerifyProtocol) -> [[Action]] {
        return [[
            Action(
                title: WalletStringKey.documentGeneralRevokeDocument.localized(),
                image: WalletGalleryConfiguration.images.deleteDocument,
                callback: { [weak self, weak view] in
                    guard let self, let view else { return }
                    self.deleteDocument(in: view)
                }
            )
        ]]
    }

    private func deleteDocument(in view: BaseView, force: Bool = false) {
        guard force else {
            handleTemplate(Constants.confirmDeletionAlert, in: view)
            return
        }
        Task { [weak self] in
            guard let self else { return }
            let documentId = self.id
            do {
                try await WalletDependencies.walletController.deleteDeferredDocument(with: documentId)
                await MainActor.run { [weak view, providerType = self.providerType] in
                    DocumentsProcessor.instance.refreshDocumentFromStorage(type: providerType)
                    NotificationCenter.default.post(name: DocumentsConstants.Notifications.documentsWasReordered, object: nil)
                    if let view {
                        WalletDependencies.templatePresenter.handle(Constants.deleteSuccessAlert, in: view) { _ in }
                    }
                }
            } catch {
                await MainActor.run { [weak view] in
                    guard let view else { return }
                    WalletDependencies.templatePresenter.handle(Constants.deleteErrorAlert, in: view) { _ in }
                }
            }
        }
    }

    private func handleTemplate(_ template: AlertTemplate, in view: BaseView) {
        WalletDependencies.templatePresenter.handle(template, in: view) { [weak self, weak view] action in
            guard let self, let view else { return }
            switch action {
            case .delete:
                self.deleteDocument(in: view, force: true)
            default:
                break
            }
        }
    }
}

private extension DeferredDocumentViewModel {
    enum Constants {
        static let confirmDeletionAlert = AlertTemplate(
            type: .middleCenterIconBlackButtonAlert,
            isClosable: false,
            data: AlertTemplateData(
                icon: .attentionBlackRound,
                title: WalletStringKey.documentDeleteAlertTitle.localized(),
                description: WalletStringKey.documentDeleteAlertDescription.localized(),
                mainButton: AlertButtonModel(
                    title: WalletStringKey.documentDeleteAlertDeleteAction.localized(),
                    icon: nil,
                    action: .delete
                ),
                alternativeButton: AlertButtonModel(
                    title: WalletStringKey.generalCancel.localized(),
                    icon: nil,
                    action: .cancel
                )
            )
        )

        static let deleteSuccessAlert = AlertTemplate(
            type: .middleCenterIconBlackButtonAlert,
            isClosable: false,
            data: AlertTemplateData(
                icon: .doneBlackRound,
                title: WalletStringKey.documentDeleteSuccessTitle.localized(),
                description: nil,
                mainButton: AlertButtonModel(
                    title: WalletStringKey.generalProblemOk.localized(),
                    icon: nil,
                    action: .ok
                ),
                alternativeButton: nil
            )
        )

        static let deleteErrorAlert = AlertTemplate(
            type: .middleCenterIconBlackButtonAlert,
            isClosable: false,
            data: AlertTemplateData(
                icon: .attentionBlackRound,
                title: WalletStringKey.documentDeleteErrorTitle.localized(),
                description: nil,
                mainButton: AlertButtonModel(
                    title: WalletStringKey.generalProblemOk.localized(),
                    icon: nil,
                    action: .ok
                ),
                alternativeButton: nil
            )
        )
    }
}
