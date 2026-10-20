import Foundation
import DiiaMVPModule
import DiiaCommonTypes
import WalletDocumentsCommonTypes

public struct AvailableDocumentType: Sendable, Equatable {
    public let name: String
    public let description: String
    public let type: String
    public let issuerId: String
    public let identifier: String

    public init(
        name: String,
        description: String,
        type: String,
        issuerId: String,
        identifier: String
    ) {
        self.name = name
        self.description = description
        self.type = type
        self.issuerId = issuerId
        self.identifier = identifier
    }
}

public protocol DocumentsCollectionContext: AnyObject {
    // MARK: - Data
    func allDocuments(actionView: BaseView?) -> [MultiDataType<DocumentModel>]
    func documents(with order: [DocTypeCode], actionView: BaseView?) -> [MultiDataType<DocumentModel>]
    func refreshDocumentFromStorage(type: String)
    func docTypesOrder() -> [DocTypeCode]

    // MARK: - Module Factories
    func createQRModule(onCollapse: @escaping () -> Void) -> BaseModule
    func createOnboardingModule(documentType: AvailableDocumentType) -> BaseModule
    func createReorderingModule() -> BaseModule
    func createActionSheet(actions: [[Action]]) -> BaseModule

    // MARK: - Cards
    func createActivateCard(action: @escaping () -> Void) -> DocumentModel
    func createAddDocumentCard(
        addCallback: @escaping () -> Void,
        changeOrderCallback: @escaping () -> Void
    ) -> DocumentModel?

    // MARK: - Document Types
    func availableDocumentTypes() async throws -> [AvailableDocumentType]
    func createDocumentListModule(onDocumentSelected: @escaping (AvailableDocumentType) -> Void) -> BaseModule

    // MARK: - Code Action
    func createCodeAction(view: BaseView) -> Callback?

    // MARK: - Revocation
    var revocationStatusUpdates: AsyncStream<Void> { get }
    var documentTypesToRefresh: [String] { get }

    // MARK: - Notifications
    var documentsReorderedNotification: Notification.Name { get }

    // MARK: - Strings
    var qrPlaceholderTitle: String { get }

    // MARK: - Lifecycle
    /// Called by the presenter on every `viewDidAppear` — i.e. when the
    /// documents collection is on screen and visible (initial appearance,
    /// tab switch back, nav pop back to root, modal dismissal). The host app
    /// uses this to flush any UI deferred while the user was elsewhere
    /// (e.g. queued deferred-issuance completion alerts).
    func documentsDidAppear()
}

public extension DocumentsCollectionContext {
    /// Default fallback: returns documents grouped by type order.
    /// Concrete implementations should override this to provide flat addition-order results.
    func allDocuments(actionView: BaseView?) -> [MultiDataType<DocumentModel>] {
        return documents(with: docTypesOrder(), actionView: actionView)
    }
}
