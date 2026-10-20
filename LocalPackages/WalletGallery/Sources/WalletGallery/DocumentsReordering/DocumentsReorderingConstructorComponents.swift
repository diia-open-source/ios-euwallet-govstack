import UIKit
import DiiaCommonTypes
import DiiaUIComponents
import WalletCore
import WalletDomainModels

public struct DocumentsReorderingListModel: Codable {
    public let items: [DocumentsReorderingItemModel]

    public init(items: [DocumentsReorderingItemModel]) {
        self.items = items
    }
}

public struct DocumentsReorderingItemModel: Codable {
    public let title: String
    public let subtitle: String?
    public let dragIcon: DSIconKey?
    public let dragIconAccessibilityLabel: String?
    public let dragIconAccessibilityHint: String?

    public init(
        title: String,
        subtitle: String?,
        dragIcon: DSIconKey?,
        dragIconAccessibilityLabel: String?,
        dragIconAccessibilityHint: String?
    ) {
        self.title = title
        self.subtitle = subtitle
        self.dragIcon = dragIcon
        self.dragIconAccessibilityLabel = dragIconAccessibilityLabel
        self.dragIconAccessibilityHint = dragIconAccessibilityHint
    }
}

public extension DSComponent where Model == DocumentsReorderingListModel {
    static var documentsReorderingList: Self { .init(key: DocumentsReorderingListBuilder.key) }
}

enum DocumentsReorderingCustomEventCode: String {
    case moveItem = "documentsReorderingMoveItem"
}

enum DocumentsReorderingCustomEventPayload {
    static let fromIndex = "fromIndex"
    static let toIndex = "toIndex"
}

final class DocumentsReorderingListView: UIView {
    private let flowLayout = UICollectionViewFlowLayout()
    private lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
    private var heightConstraint: NSLayoutConstraint?

    private var items: [DocumentsReorderingItemModel] = []
    private var previousDestination: IndexPath = IndexPath(item: 0, section: 0)
    private var eventHandler: ((ConstructorItemEvent) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateCollectionHeight()
    }

    func configure(model: DocumentsReorderingListModel, eventHandler: @escaping (ConstructorItemEvent) -> Void) {
        items = model.items
        self.eventHandler = eventHandler
        collectionView.reloadData()
        updateCollectionHeight()
    }

    private func setupUI() {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .clear

        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .clear
        collectionView.alwaysBounceVertical = false
        collectionView.isScrollEnabled = false

        flowLayout.minimumInteritemSpacing = Constants.interitemSpacing
        flowLayout.minimumLineSpacing = Constants.interitemSpacing
        flowLayout.sectionInset = Constants.sectionInset
        flowLayout.estimatedItemSize = Constants.estimatedItemSize

        collectionView.register(cellType: DocumentReorderingCell.self)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.dragDelegate = self
        collectionView.dropDelegate = self
        collectionView.dragInteractionEnabled = true

        addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        heightConstraint = collectionView.heightAnchor.constraint(equalToConstant: 0)
        heightConstraint?.isActive = true
    }

    private func updateCollectionHeight() {
        collectionView.layoutIfNeeded()
        heightConstraint?.constant = collectionView.collectionViewLayout.collectionViewContentSize.height
        invalidateIntrinsicContentSize()
    }
}

extension DocumentsReorderingListView: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        items.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: DocumentReorderingCell = collectionView.dequeueReusableCell(for: indexPath)
        cell.configure(with: items[indexPath.item])
        return cell
    }
}

extension DocumentsReorderingListView: UICollectionViewDragDelegate, UICollectionViewDropDelegate {
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        let itemProvider = NSItemProvider()
        let dragItem = UIDragItem(itemProvider: itemProvider)
        dragItem.localObject = indexPath
        return [dragItem]
    }

    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        var currentDestination = IndexPath(item: 0, section: 0)
        guard destinationIndexPath != nil else { return .init(operation: .forbidden) }

        collectionView.performUsingPresentationValues {
            currentDestination = collectionView.indexPathForItem(at: session.location(in: collectionView))
                ?? IndexPath(item: 0, section: 0)
        }

        if currentDestination != previousDestination {
            previousDestination = currentDestination
            guard collectionView.cellForItem(at: currentDestination) != nil else { return .init(operation: .forbidden) }
            UIAccessibility.post(
                notification: .announcement,
                argument: WalletStringKey.documentsAccessibilityChangeOrderAnnounce
                    .formattedLocalized(arguments: currentDestination.item + 1, items.count)
            )
        }

        return .init(operation: .move, intent: .insertAtDestinationIndexPath)
    }

    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        guard let destinationIndexPath = coordinator.destinationIndexPath,
              let dragItem = coordinator.items.last?.dragItem,
              let startIndexPath = dragItem.localObject as? IndexPath
        else { return }

        collectionView.performBatchUpdates({ [weak self] in
            guard let self else { return }
            let item = items.remove(at: startIndexPath.item)
            items.insert(item, at: destinationIndexPath.item)
            collectionView.deleteItems(at: [startIndexPath])
            collectionView.insertItems(at: [destinationIndexPath])
        })

        updateCollectionHeight()
        eventHandler?(
            .customEvent(
                CustomConstructorEvent(
                    code: DocumentsReorderingCustomEventCode.moveItem.rawValue,
                    payload: [
                        DocumentsReorderingCustomEventPayload.fromIndex: startIndexPath.item,
                        DocumentsReorderingCustomEventPayload.toIndex: destinationIndexPath.item
                    ]
                )
            )
        )
        coordinator.drop(dragItem, toItemAt: destinationIndexPath)
    }
}

public struct DocumentsReorderingListBuilder: DSViewBuilderProtocol {
    public static let key = "documentsReorderingList"

    public init() {}

    public func makeView(
        from object: AnyCodable,
        withPadding padding: DSViewPaddingType,
        viewFabric: DSViewFabric?,
        eventHandler: @escaping (ConstructorItemEvent) -> Void
    ) -> UIView? {
        guard let model: DocumentsReorderingListModel = object.parseValue(forKey: Self.key) else { return nil }
        let view = DocumentsReorderingListView()
        view.configure(model: model, eventHandler: eventHandler)
        return view
    }
}

private extension DocumentsReorderingListView {
    enum Constants {
        static let estimatedItemSize = CGSize(width: UIScreen.main.bounds.width - 32, height: 64)
        static let sectionInset = UIEdgeInsets(top: 8, left: 16, bottom: 16, right: 16)
        static let interitemSpacing: CGFloat = 8
    }
}
