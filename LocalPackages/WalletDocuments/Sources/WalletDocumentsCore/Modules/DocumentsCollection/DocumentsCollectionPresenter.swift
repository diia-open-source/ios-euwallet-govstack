
import UIKit
import ReactiveKit
import DiiaMVPModule
import DiiaCommonTypes
import DiiaUIComponents
import WalletDocumentsCommonTypes

public protocol DocumentsCollectionAction: BasePresenter {
    var haveAdditionalCard: Bool { get }
    func viewDidAppear()
    func onAnimationComplete()
    func numberOfItems() -> Int
    func processAction(action: String)
    func itemAtIndex(index: Int) -> MultiDataType<DocumentModel>?
    func stackClicked(at index: Int)
    func stop()
}

extension DocumentsCollectionAction {
    public func onAnimationComplete() {}
    public func stackClicked(at index: Int) {}
}

final class DocumentsCollectionPresenter: DocumentsCollectionAction {

    // MARK: - Properties
    weak var view: DocumentsCollectionView?
    private let context: DocumentsCollectionContext
    private let viewStateFactory: DocumentsCollectionViewStateFactoryProtocol

    private var documents: [MultiDataType<DocumentModel>] = []

    // A scroll that can't run yet because the carousel isn't on screen, retried from `scrollDocIfNeeded()`.
    private enum PendingScroll {
        case docType(DocTypeCode) // deep-link to a specific document type (router / tab bar)
        case first                // a new document was just added (AddDocument or QR/issuance)
    }
    private var pendingScroll: PendingScroll?

    private let bag = DisposeBag()
    private var revocationObserverTask: Task<Void, Never>?
    private var notificationObserver: NSObjectProtocol?

    // MARK: - Life Cycle
    init(
        context: DocumentsCollectionContext,
        view: DocumentsCollectionView,
        viewStateFactory: DocumentsCollectionViewStateFactoryProtocol
    ) {
        self.context = context
        self.view = view
        self.viewStateFactory = viewStateFactory
    }

    deinit {
        stop()
    }

    // MARK: - Public
    func configureView() {
        notificationObserver = NotificationCenter.default.addObserver(
            forName: context.documentsReorderedNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.documentsWasUpdated()
        }

        // Observe revocation status changes via context stream
        revocationObserverTask = Task { [weak self] in
            guard let self else { return }
            for await _ in context.revocationStatusUpdates {
                await MainActor.run { self.documentsWasUpdated() }
            }
        }

        processDocuments()
        view?.configureQRPlaceholder(title: context.qrPlaceholderTitle, link: "")
    }

    func stop() {
        revocationObserverTask?.cancel()
        revocationObserverTask = nil
        if let observer = notificationObserver {
            NotificationCenter.default.removeObserver(observer)
            notificationObserver = nil
        }
    }

    func onAnimationComplete() {
        let qrModule = context.createQRModule { [weak self] in
            self?.view?.collapseQRPlaceholder()
        }
        view?.showChild(module: qrModule)
    }

    var haveAdditionalCard: Bool {
        return true
    }

    func viewDidAppear() {
        scrollDocIfNeeded()
        context.documentsDidAppear()
    }

    func numberOfItems() -> Int {
        return documents.count
    }

    func itemAtIndex(index: Int) -> MultiDataType<DocumentModel>? {
        guard documents.indices.contains(index) else { return nil }
        return documents[index]
    }

    func processAction(action: String) {
        let docCode: DocTypeCode = action
        if !scrollToDoc(type: docCode) {
            pendingScroll = .docType(docCode)
        }
    }

    func documentsWasUpdated() {
        guard view != nil else { return }
        for type in context.documentTypesToRefresh {
            context.refreshDocumentFromStorage(type: type)
        }
        processDocuments()
        scrollDocIfNeeded()
    }
}

// MARK: - Private Methods
extension DocumentsCollectionPresenter {
    private func processDocuments() {
        guard let view else { return }
        let rawDocuments = context.allDocuments(actionView: view)

        let state = viewStateFactory.make(
            documents: rawDocuments,
            activateCardProvider: { [context] in
                context.createActivateCard(action: { [weak self] in
                    self?.openDocumentListModule()
                })
            },
            addCardProvider: { [context] in
                context.createAddDocumentCard(
                    addCallback: { [weak self] in
                        self?.openDocumentListModule()
                    },
                    changeOrderCallback: { [weak self] in
                        guard let self else { return }
                        self.view?.open(module: self.context.createReorderingModule())
                    }
                )
            }
        )

        view.setQRPlaceholder(visibility: state.isQRPlaceholderVisible)

        // Always refresh the UI.
        // `processDocuments()` is driven by explicit triggers — the `documentsWasReordered` notification and the `revocationStatusUpdates` AsyncStream — never a tight loop, so unconditionally rebuilding is cheap.
        // The previous `elementsEqual({ $0.model == $1.getValue().model })` short-circuit looked only at the underlying `DSDocumentData` payload and missed every card-state transition that lives outside it: `isRevoked` and `isExpired` are private on `PidCardViewModel` / `MdlCardViewModel`, so flipping either left `.model` unchanged and the diff returned "equal" — the red revoked/expired overlay never appeared until the next time `.model` itself changed (e.g. add/remove another document).
        // If a tighter optimisation is needed later, expose a rendering fingerprint on `DocumentModel` that includes revocation + expiry + any other derived state and compare that.
        // A grown card count means a document was just added (AddDocument or QR/issuance).
        // Guard on the previous list being non-empty so the initial population doesn't count as an add.
        if !self.documents.isEmpty, state.documents.count > self.documents.count {
            pendingScroll = .first
        }
        self.documents = state.documents
        view.updateDocuments()
    }

    private func openDocumentListModule() {
        view?.open(module: context.createDocumentListModule(
            onDocumentSelected: { [weak self] documentType in
                guard let self else { return }
                self.view?.open(module: self.context.createOnboardingModule(documentType: documentType))
            }
        ))
    }

    @discardableResult
    private func scrollToDoc(type: DocTypeCode) -> Bool {
        guard let view, view.isVisible() else { return false }
        var index: Int?

        for (i, doc) in documents.enumerated() {
            if doc.getValue().docType?.isDocCodeSameAs(otherDocCode: type) ?? false {
                index = i
                break
            }
        }

        guard let item = index else { return false }
        view.scroll(to: IndexPath(item: item, section: 0), animated: true)
        return true
    }

    private func scrollDocIfNeeded() {
        let scrolled: Bool
        switch pendingScroll {
        case .docType(let docType):
            scrolled = scrollToDoc(type: docType)
        case .first:
            scrolled = scrollToFirst()
        case .none:
            return
        }
        if scrolled {
            pendingScroll = nil
        }
    }

    @discardableResult
    private func scrollToFirst() -> Bool {
        guard let view, view.isVisible(), !documents.isEmpty else { return false }
        view.scroll(to: IndexPath(item: 0, section: 0), animated: true)
        return true
    }
}
