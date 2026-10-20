
import Foundation
import DiiaMVPModule
import DiiaCommonTypes
import DiiaUIComponents
import WalletDocumentsCore
import WalletDocumentsCommonTypes
import WalletCore
import WalletDomainModels
import WalletScannerBarcode
import WalletGallery
import WalletAddDocument
import WalletIssuing
import WalletSharing

private struct ExistingDocumentKey: Hashable {
    let type: String
    let issuerId: String
}

final class DocumentsCollectionContextImpl: DocumentsCollectionContext {
    private let qrCodeScannerModuleFactory: QRCodeScannerModuleFactoryProtocol

    init(qrCodeScannerModuleFactory: QRCodeScannerModuleFactoryProtocol) {
        self.qrCodeScannerModuleFactory = qrCodeScannerModuleFactory
    }

    // MARK: - Data
    func allDocuments(actionView: BaseView?) -> [MultiDataType<DocumentModel>] {
        return DocumentsProcessor.instance.allDocuments(actionView: actionView)
    }

    func documents(with order: [DocTypeCode], actionView: BaseView?) -> [MultiDataType<DocumentModel>] {
        return DocumentsProcessor.instance.documents(with: order, actionView: actionView)
    }

    func refreshDocumentFromStorage(type: String) {
        DocumentsProcessor.instance.refreshDocumentFromStorage(type: type)
    }

    func docTypesOrder() -> [DocTypeCode] {
        return DocumentReorderingService.shared.docTypesOrder()
    }

    // MARK: - Module Factories
    func createQRModule(onCollapse: @escaping () -> Void) -> BaseModule {
        return DocumentsQRModule(
            closeButtonImage: R.image.clear.image,
            onClose: onCollapse
        )
    }

    func createOnboardingModule(documentType: AvailableDocumentType) -> BaseModule {
        return WalletOnboardingModule(
            documentType: documentType,
            backgroundImage: R.image.light_background.image,
            restartCallback: {
                let docType = WalletDocumentType(rawValue: documentType.type)?.docType
                AppRouter.instance.popToTab(with: .documents(type: docType))
            }
        )
    }

    func createReorderingModule() -> BaseModule {
        return DocumentsReorderingModule(
            orderService: DocumentReorderingService.shared,
            documentsProvider: DocumentsReorderingDocumentsProvider(),
            viewStateFactory: DocumentsReorderingViewStateFactory()
        )
    }

    func createActionSheet(actions: [[Action]]) -> BaseModule {
        return ActionSheetModule(actions: actions)
    }

    // MARK: - Cards
    func createActivateCard(action: @escaping () -> Void) -> DocumentModel {
        return ActivatePidDocumentViewModel(activateCallback: action)
    }

    func createAddDocumentCard(
        addCallback: @escaping () -> Void,
        changeOrderCallback: @escaping () -> Void
    ) -> DocumentModel? {
        return AddNewDocumentViewModel(
            addDocumentCallback: addCallback,
            changeOrderCallback: changeOrderCallback
        )
    }

    // MARK: - Document Types
    func availableDocumentTypes() async throws -> [AvailableDocumentType] {
        let walletController = WalletDependencies.walletController
        let types = try await walletController.fetchAvailableDocumentTypes()
        // Deferred docs count as "already in flight" for picker dedup, so a user with a deferred PID won't be re-offered the same PID slot.
        let existingDocuments = Set(
            walletController.fetchAllDocumentsIncludingDeferred().compactMap { document -> ExistingDocumentKey? in
                guard let issuerId = document.credentialIssuerIdentifier else {
                    return nil
                }

                return ExistingDocumentKey(
                    type: document.docType,
                    issuerId: normalizedIssuerId(issuerId)
                )
            }
        )
        // MDL gating intentionally counts only ISSUED PIDs — a deferred PID is not yet usable for the MDL prerequisite, so the user has to wait until it lands before MDL becomes available.
        let hasIssuedPidDocument = walletController.fetchAllDocuments().contains {
            WalletDocumentType.allPidTypes.map(\.rawValue).contains($0.docType)
        }
        let allowedTypes = Set(
            WalletDocumentType.allPidTypes.map(\.rawValue)
            + (hasIssuedPidDocument ? [WalletDocumentType.mdl.rawValue] : [])
        )

        return types
            .map {
                AvailableDocumentType(
                    name: $0.name,
                    description: R.Strings.document_issuer.localized(with: $0.issuerId),
                    type: $0.docType,
                    issuerId: $0.issuerId,
                    identifier: $0.identifier
                )
            }
            .filter { allowedTypes.contains($0.type) }
            .filter {
                !existingDocuments.contains(
                    ExistingDocumentKey(type: $0.type, issuerId: normalizedIssuerId($0.issuerId))
                )
            }
            .sorted { lhs, rhs in
                // Primary: issuer order — bbWalletIssuer, then demoIssuer1, then demoIssuer2.
                let lhsIssuerOrder = issuerPriority(lhs.issuerId)
                let rhsIssuerOrder = issuerPriority(rhs.issuerId)
                if lhsIssuerOrder != rhsIssuerOrder {
                    return lhsIssuerOrder > rhsIssuerOrder
                }

                // Secondary: document type — PID (mDoc), PID (SD-JWT), then mDL.
                let lhsTypePriority = documentTypePriority(lhs.type)
                let rhsTypePriority = documentTypePriority(rhs.type)
                if lhsTypePriority != rhsTypePriority {
                    return lhsTypePriority < rhsTypePriority
                }

                // Fallback for any ties (e.g. unknown issuers landing on the same priority).
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
    }
    
    func createDocumentListModule(onDocumentSelected: @escaping (AvailableDocumentType) -> Void) -> BaseModule {
        return AddDocumentModule(
            documentTypesLoader: { [weak self] in
                guard let self else { return [] }
                return try await self.availableDocumentTypes()
            },
            onDocumentSelected: onDocumentSelected,
            documentTypeMapper: AddDocumentDocumentTypeMapper(),
            viewStateFactory: AddDocumentViewStateFactory(),
            presentQRScanner: { [weak self] view in
                guard let self else { return }
                CameraAccessChecker.askCameraAccess(permissionDeniedHandler: AccessHelper.cameraPermissionDeniedHandler) { granted in
                    guard granted else { return }
                    let delegate = WalletQRScannerHelper(presentingView: view)
                    view.open(module: self.qrCodeScannerModuleFactory.make(delegate: delegate))
                }
            },
            qrButtonImage: R.image.ellipseQrScan.image
        )
    }

    // MARK: - Code Action
    func createCodeAction(view: BaseView) -> Callback? {
        return { [weak view] in
            guard let view else { return }
            view.showChild(module: DocumentsQRModule(closeButtonImage: R.image.clear.image))
        }
    }

    // MARK: - Revocation
    var revocationStatusUpdates: AsyncStream<Void> {
        return WalletDependencies.walletLifecycle.revocationService.statusUpdates
    }

    // MARK: - Lifecycle
    /// The documents-collection presenter calls this every time the view
    /// appears (initial, tab-switch-back, nav-pop-back-to-root, modal
    /// dismissal). Use it to flush any UI we deferred while the user was off
    /// the Documents tab root — e.g. a queued deferred-issuance completion
    /// alert waiting for the right moment to surface.
    func documentsDidAppear() {
        WalletDependencies.walletLifecycle.flushPendingAlerts()
    }

    var documentTypesToRefresh: [String] {
        return [DocType.pidDocument.rawValue, DocType.mdlDocument.rawValue]
    }

    // MARK: - Notifications
    var documentsReorderedNotification: Notification.Name {
        return DocumentsConstants.Notifications.documentsWasReordered
    }

    // MARK: - Strings
    var qrPlaceholderTitle: String {
        return R.Strings.feed_qr_title.localized()
    }
}

private extension DocumentsCollectionContextImpl {
    func documentTypePriority(_ type: String) -> Int {
        switch type {
        case WalletDocumentType.pidMdoc.rawValue:
            return 0
        case WalletDocumentType.pidSdJwt.rawValue:
            return 1
        case WalletDocumentType.mdl.rawValue:
            return 2
        default:
            return Int.max
        }
    }

    func issuerPriority(_ issuerId: String) -> Int {
        // Higher number = earlier in the picker. Order is driven by `displayPriority` in wallet-config.json. Unknown issuers sink to the bottom.
        WalletConfiguration.shared.issuer(forHost: issuerId)?.displayPriority ?? Int.min
    }

    func normalizedIssuerId(_ issuerId: String) -> String {
        if let url = URL(string: issuerId), let host = url.host {
            let path = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            return (path.isEmpty ? host : "\(host)/\(path)").lowercased()
        }
        return issuerId
            .replacingOccurrences(of: "https://", with: "")
            .replacingOccurrences(of: "http://", with: "")
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            .lowercased()
    }
}
