
import UIKit
import DiiaMVPModule
import DiiaUIComponents
import DiiaCommonTypes
import WalletDocumentsCommonTypes

protocol DocumentsCollectionView: BaseView {
    func updateDocuments()
    func setStatusText(statusText: String?)
    func scroll(to indexPath: IndexPath, animated: Bool)
    func flipCurrentItem()
    func isVisible() -> Bool

    func collapseQRPlaceholder()
    func configureQRPlaceholder(title: String, link: String)
    func setQRPlaceholder(visibility isVisible: Bool)
}

final class DocumentsCollectionViewController: UIViewController {

    // MARK: - Properties
    var presenter: DocumentsCollectionAction!

    private let collectionView: UICollectionView = {
        let view = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        view.clipsToBounds = true
        view.showsHorizontalScrollIndicator = false
        view.showsVerticalScrollIndicator = false
        view.contentInsetAdjustmentBehavior = .never
        return view
    }()

    private let scrollingPageControl: ScrollingPageControl = {
        let view = ScrollingPageControl()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        return view
    }()

    private let statusTextView: FloatingTextLabel = {
        let view = FloatingTextLabel()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        return view
    }()

    private let dimmedOverlayView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isUserInteractionEnabled = false
        view.backgroundColor = .clear
        return view
    }()

    private var dateLabelTopFromDocumentCenterConstraint: NSLayoutConstraint!

    private let qrPlaceholderView = DocumentsQRPlaceholderView()

    private var initialQRPosition: CGFloat { view.frame.height * 0.925 }
    private var finalQRPosition: CGFloat {
        (collectionView.frame.height - DocumentsLayoutProvider.cardHeight) / 2 + view.safeAreaInsets.top
    }
    private var isQRExpanded = false
    private var isQRBaseVisible: Bool = false

    private var lastIndexPath: IndexPath?
    private var visibleIndexPath: IndexPath?
    private var needUpdatesUI: Bool = false
    private var needLateUpdatesUI: Bool = false
    var actionFabric: DocumentActionsFabricProtocol?

    private var bgColorHex: String!
    private var cardColorHex: String!

    private var pagingData: (current: Int, total: Int) = (0, 0) {
        didSet {
            scrollingPageControl.isHidden = pagingData.total < Constants.minAmountToShowPages

            scrollingPageControl.pages = pagingData.total
            scrollingPageControl.selectedPage = pagingData.current

            scrollingPageControl.maxDots = Constants.maxDots(for: pagingData.total)
            scrollingPageControl.centerDots = Constants.centerDots(for: pagingData.total)
            scrollingPageControl.dotSize = Constants.dotSize
        }
    }

    // MARK: - Lifecycle
    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        // The presenter can't cancel its own revocation task from `deinit`, so trigger teardown here.
        presenter?.stop()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .clear
        setupSubviews()
        setupConstraints()

        view.addSubview(qrPlaceholderView)
        collectionView.register(DocumentCollectionCell.self, forCellWithReuseIdentifier: DocumentCollectionCell.reuseID)
        let layout = ZoomAndSnapFlowLayout(
            itemSize: .init(width: DocumentsLayoutProvider.cardWidth,
                            height: DocumentsLayoutProvider.cardHeight),
            minimumSpacing: DocumentsLayoutProvider.cardInteritemSpacing
        )
        layout.delegate = self
        collectionView.collectionViewLayout = layout
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.decelerationRate = .fast

        scrollingPageControl.dotColor = Constants.scrollingDotColor
        scrollingPageControl.selectedColor = .white
        scrollingPageControl.accessibilityActionsDelegate = self

        setupPanGestureRecognizerOnQRView()
        qrPlaceholderView.accessibilityActivationHandler = { [weak self] in
            guard let self else { return }
            self.isQRExpanded ? self.collapseQRView() : self.expandQRView()
        }
        updatePageControlPosition()
        setupAccessibility()

        presenter.configureView()
    }

    // MARK: - Layout
    private func setupSubviews() {
        view.addSubview(collectionView)
        view.addSubview(scrollingPageControl)
        view.addSubview(statusTextView)
        view.addSubview(dimmedOverlayView)
    }

    private func setupConstraints() {
        let safeArea = view.safeAreaLayoutGuide

        dateLabelTopFromDocumentCenterConstraint = scrollingPageControl.topAnchor.constraint(
            equalTo: collectionView.centerYAnchor,
            constant: Constants.defaultPageControlTopOffset
        )

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: safeArea.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor),
            safeArea.bottomAnchor.constraint(equalTo: collectionView.bottomAnchor, constant: Constants.collectionBottomInset),

            scrollingPageControl.widthAnchor.constraint(equalToConstant: Constants.pageControlWidth),
            scrollingPageControl.heightAnchor.constraint(equalToConstant: Constants.pageControlHeight),
            scrollingPageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            dateLabelTopFromDocumentCenterConstraint,

            statusTextView.heightAnchor.constraint(equalToConstant: Constants.statusTextHeight),
            statusTextView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor),
            statusTextView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor),
            statusTextView.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor),

            dimmedOverlayView.topAnchor.constraint(equalTo: view.topAnchor),
            dimmedOverlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            dimmedOverlayView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor),
            dimmedOverlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        visibleIndexPath = lastIndexPath
        if needUpdatesUI {
            updateUI(animated: false)
        } else {
            needLateUpdatesUI = true
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        presenter.viewDidAppear()
        if needLateUpdatesUI, let visible = visibleIndexPath {
            (collectionView.cellForItem(at: visible) as? DocumentCollectionCell)?.changeFocusing(isFocused: true)
            needLateUpdatesUI = false
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        collectionView.visibleCells.forEach { cell in
            (cell as? DocumentCollectionCell)?.shouldHide()
            (cell as? DocumentCollectionCell)?.changeFocusing(isFocused: false)
        }
        if let indexPath = lastIndexPath {
            collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
            setVisibleItem(indexPath: indexPath)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updatePageControlPosition()
        let isAnimating = qrPlaceholderView.layer.animationKeys()?.isEmpty == false
        let y: CGFloat
        if isAnimating {
            y = qrPlaceholderView.frame.origin.y
        } else if qrPlaceholderView.isHidden {
            y = view.frame.height
        } else {
            y = initialQRPosition
        }
        qrPlaceholderView.frame = CGRect(
            x: Constants.cardSidePadding,
            y: y,
            width: collectionView.frame.width - Constants.cardSidePadding * 2,
            height: DocumentsLayoutProvider.cardHeight
        )
    }

    // MARK: - Helping methods
    private func setVisibleItem(indexPath: IndexPath?, animated: Bool = true) {
        visibleIndexPath = indexPath
        collectionView.indexPathsForVisibleItems.forEach { [weak self] indexPath in
            guard let self else { return }
            let isVisible = indexPath == self.visibleIndexPath || self.visibleIndexPath == nil
            let cell = self.collectionView.cellForItem(at: indexPath) as? DocumentCollectionCell
            guard (self.pagingData.total - 1) != indexPath.row || !self.presenter.haveAdditionalCard else {
                cell?.setContentHidden(isHidden: false, animated: false)
                return
            }
            cell?.setContentHidden(isHidden: !isVisible, animated: animated)
            if isVisible {
                UIAccessibility.post(notification: .layoutChanged, argument: cell)
            }
        }
    }

    private func setupPanGestureRecognizerOnQRView() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        qrPlaceholderView.addGestureRecognizer(panGesture)
    }

    private func updatePageControlPosition() {
        let lift = view.bounds.width <= Constants.narrowScreenMaxWidth ? Constants.narrowScreenPageControlLift : 0
        dateLabelTopFromDocumentCenterConstraint.constant = DocumentsLayoutProvider.cardHeight / 2 + Constants.pageInset - lift
    }

    // MARK: - QR
    @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        guard !isQRExpanded else { return }
        let translation = gesture.translation(in: view)

        switch gesture.state {
        case .changed:
            let currentPosition = max(finalQRPosition, initialQRPosition + translation.y)
            qrPlaceholderView.frame.origin.y = currentPosition

            let progress = (initialQRPosition - currentPosition) / (initialQRPosition - finalQRPosition)
            setBackgroundAlpha(progress * Constants.completeDimmedAlpha)
        case .ended:
            isQRExpanded = qrPlaceholderView.frame.origin.y < view.frame.height * 0.7
            if isQRExpanded {
                expandQRView()
            } else {
                collapseQRView()
            }
        default:
            break
        }
    }

    private func expandQRView() {
        isQRExpanded = true
        UIView.animate(
            withDuration: 0.35,
            animations: { [weak self] in
                guard let self else { return }
                self.qrPlaceholderView.frame.origin.y = self.finalQRPosition
                self.setBackgroundAlpha(Constants.completeDimmedAlpha)
                self.presenter.onAnimationComplete()
            }
        )
    }

    private func collapseQRView() {
        isQRExpanded = false
        UIView.animate(withDuration: 0.35) {
            self.qrPlaceholderView.frame.origin.y = self.initialQRPosition
            self.setBackgroundAlpha(.zero)
        }
    }

    private func setBackgroundAlpha(_ alpha: CGFloat) {
        dimmedOverlayView.backgroundColor = .black.withAlphaComponent(alpha)
    }

    // MARK: - Accessibility
    override func accessibilityScroll(_ direction: UIAccessibilityScrollDirection) -> Bool {
        if direction == .right || direction == .left {
            let proposedContentOffset: CGPoint
            switch direction {
            case .right:
                proposedContentOffset = .init(x: collectionView.contentOffset.x - collectionView.frame.size.width/2, y: .zero)
            case .left:
                proposedContentOffset = .init(x: collectionView.contentOffset.x + collectionView.frame.size.width/2, y: .zero)
            default:
                return false
            }
            let targetContentOffset = (collectionView.collectionViewLayout as? ZoomAndSnapFlowLayout)?.targetContentOffset(forProposedContentOffset: proposedContentOffset,
                                                                                                                           withScrollingVelocity: .zero) ?? .zero
            collectionView.setContentOffset(targetContentOffset, animated: true)

            onMainQueueAfter(time: Constants.animationDuration) { [weak self] in
                self?.setVisibleItem(indexPath: self?.lastIndexPath)
            }

            return true
        }
        return false
    }

    private func setupAccessibility() {
        statusTextView.isAccessibilityElement = true
        statusTextView.accessibilityLabel = R.Strings.documents_collection_accessibility_reachability_error.localized()
        scrollingPageControl.isAccessibilityElement = false
    }
}

// MARK: - View logic
extension DocumentsCollectionViewController: DocumentsCollectionView {
    func setQRPlaceholder(visibility isVisible: Bool) {
        isQRBaseVisible = isVisible
        updateQRPlaceholderVisibility()
    }

    private func isShowingAdditionalCard(at indexPath: IndexPath?) -> Bool {
        guard let indexPath, presenter.haveAdditionalCard, pagingData.total > 0 else { return false }
        return indexPath.item == pagingData.total - 1
    }

    private func updateQRPlaceholderVisibility(animated: Bool = true) {
        let shouldShow = isQRBaseVisible && !isShowingAdditionalCard(at: lastIndexPath)
        setQRPlaceholderVisible(shouldShow, animated: animated)
    }

    private func setQRPlaceholderVisible(_ visible: Bool, animated: Bool) {
        guard view.window != nil, animated else {
            qrPlaceholderView.layer.removeAllAnimations()
            qrPlaceholderView.isHidden = !visible
            qrPlaceholderView.alpha = visible ? 1 : 0
            qrPlaceholderView.frame.origin.y = initialQRPosition
            return
        }
        if visible {
            if !qrPlaceholderView.isHidden && qrPlaceholderView.alpha == 1 { return }
            qrPlaceholderView.isHidden = false
            qrPlaceholderView.alpha = 0
            qrPlaceholderView.frame.origin.y = view.frame.height
            UIView.animate(
                withDuration: Constants.qrVisibilityAnimationDuration,
                delay: 0,
                options: [.beginFromCurrentState, .curveEaseOut],
                animations: { [weak self] in
                    guard let self else { return }
                    self.qrPlaceholderView.alpha = 1
                    self.qrPlaceholderView.frame.origin.y = self.initialQRPosition
                }
            )
        } else {
            if qrPlaceholderView.isHidden { return }
            UIView.animate(
                withDuration: Constants.qrVisibilityAnimationDuration,
                delay: 0,
                options: [.beginFromCurrentState, .curveEaseIn],
                animations: { [weak self] in
                    guard let self else { return }
                    self.qrPlaceholderView.alpha = 0
                    self.qrPlaceholderView.frame.origin.y = self.view.frame.height
                },
                completion: { [weak self] finished in
                    guard let self, finished else { return }
                    self.qrPlaceholderView.isHidden = true
                    self.qrPlaceholderView.frame.origin.y = self.initialQRPosition
                }
            )
        }
    }

    func collapseQRPlaceholder() {
        collapseQRView()
    }

    func configureQRPlaceholder(title: String, link: String) {
        qrPlaceholderView.configure(title: title, link: link)
    }

    func updateDocuments() {
        collectionView.reloadData()
        if view.window == nil {
            needUpdatesUI = true
            return
        }
        updateUI(animated: true)
    }

    private func updateUI(animated: Bool) {
        needUpdatesUI = false
        (collectionView.collectionViewLayout as? ZoomAndSnapFlowLayout)?.cachedAttributes = []
        collectionView.layoutIfNeeded()
        var indexPath: IndexPath = visibleIndexPath ?? IndexPath(item: 0, section: 0)
        let count = presenter.numberOfItems()
        if indexPath.item >= count {
            indexPath.item = count - 1
        }
        forceUpdateIndexPath(index: indexPath, animated: animated)
        setVisibleItem(indexPath: indexPath, animated: animated)

        pagingData.total = presenter.numberOfItems()
        updateQRPlaceholderVisibility()
    }

    func setStatusText(statusText: String?) {
        statusTextView.labelText = statusText
        if statusText != nil {
            statusTextView.isHidden = false
            statusTextView.animate()
        } else {
            statusTextView.isHidden = true
            statusTextView.stopAnimation()
        }
    }

    func scroll(to indexPath: IndexPath, animated: Bool) {
        guard
            let flowLayout = collectionView.collectionViewLayout as? ZoomAndSnapFlowLayout,
            let cellFrame = flowLayout.layoutAttributesForItem(at: indexPath)?.frame
        else {
            return
        }

        let additionalOffset = (collectionView.bounds.width - cellFrame.width) / 2
        let offsetX = cellFrame.minX - additionalOffset

        collectionView.setContentOffset(CGPoint(x: offsetX, y: 0), animated: animated)
        forceUpdateIndexPath(index: indexPath)
        setVisibleItem(indexPath: indexPath, animated: false)
    }

    func flipCurrentItem() {
        if let indexPath = lastIndexPath, let cell = collectionView.cellForItem(at: indexPath) as? DocumentCollectionCell {
            cell.flip()
        }
    }

    func isVisible() -> Bool {
        return view.window != nil && !view.needsUpdateConstraints()
    }
}

// MARK: - UICollectionViewDataSource
extension DocumentsCollectionViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return presenter.numberOfItems()
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return collectionView.dequeueReusableCell(withReuseIdentifier: DocumentCollectionCell.reuseID, for: indexPath) as? DocumentCollectionCell
            ?? UICollectionViewCell()
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard
            let cell = cell as? DocumentCollectionCell,
            let dataType = presenter.itemAtIndex(index: indexPath.item)
        else {
            return
        }

        let moreAction = actionFabric?.getAction(for: dataType, view: self, flipper: cell)

        let viewModel = DocumentCollectionCellViewModel(
            documentData: dataType,
            contextMenuCallback: moreAction,
            cardStackCallback: nil,
            accessibilityActionsMenuCallBack: nil
        )

        cell.configure(with: viewModel)

        if let color = cardColorHex {
            cell.setBackgroundColor(color: UIColor(color))
        }

        let cellIsHidden = !(indexPath == visibleIndexPath || visibleIndexPath == nil)
        cell.setContentHidden(isHidden: cellIsHidden, animated: false)
    }

}

// MARK: - UICollectionViewDelegate
extension DocumentsCollectionViewController: UICollectionViewDelegate {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        (collectionView.collectionViewLayout as? ZoomAndSnapFlowLayout)?.startCenterX = collectionView.contentOffset.x + collectionView.frame.size.width/2
        setVisibleItem(indexPath: nil)
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        setVisibleItem(indexPath: lastIndexPath)
    }
}

// MARK: - ZoomAndSnapFlowLayoutDelegate
extension DocumentsCollectionViewController: ZoomAndSnapFlowLayoutDelegate {
    func didChangeIndexPathInTheMiddle(_ indexPath: IndexPath?) {
        if let newIndex = indexPath, (lastIndexPath != newIndex) {
            forceUpdateIndexPath(index: newIndex)
        }
    }

    private func forceUpdateIndexPath(index: IndexPath, animated: Bool = true) {
        if let last = lastIndexPath, let cell = collectionView.cellForItem(at: last) as? DocumentCollectionCell {
            cell.shouldHide()
            cell.changeFocusing(isFocused: false)
        }
        if let cell = collectionView.cellForItem(at: index) as? DocumentCollectionCell {
            cell.changeFocusing(isFocused: true)
        }
        lastIndexPath = index
        pagingData.current = index.item
        updateQRPlaceholderVisibility()
    }
}

// MARK: - MainEmbeddable
extension DocumentsCollectionViewController: MainEmbeddable {
    func onSameSelected() {
        let initialIndexPath = IndexPath(item: .zero, section: .zero)
        collectionView.scrollToItem(at: initialIndexPath, at: .centeredHorizontally, animated: true)

        forceUpdateIndexPath(index: initialIndexPath)
        setVisibleItem(indexPath: initialIndexPath, animated: false)
    }

    func processAction(action: String) {
        presenter.processAction(action: action)
    }
}

// MARK: - ScrollingPageControlAccessibilityActionsDelegate
extension DocumentsCollectionViewController: ScrollingPageControlAccessibilityActionsDelegate {
    func onScroll(direction: UIAccessibilityScrollDirection) {
        _ = accessibilityScroll(direction)
    }
}

// MARK: - Constants
extension DocumentsCollectionViewController {
    private enum Constants {
        static let scrollingDotColor = UIColor.init(white: 1, alpha: 0.4)
        static let animationDuration: TimeInterval = 0.25
        static let minAmountToShowPages = 2
        static let pagesAlpha: CGFloat = 0.3

        static let pageInset: CGFloat = 16
        static let narrowScreenMaxWidth: CGFloat = 375
        static let narrowScreenPageControlLift: CGFloat = 20
        static let cardSidePadding: CGFloat = 32
        static let completeDimmedAlpha: CGFloat = 0.5
        static let qrVisibilityAnimationDuration: TimeInterval = 0.3

        // Layout
        static let defaultPageControlTopOffset: CGFloat = 200
        static let collectionBottomInset: CGFloat = 16
        static let pageControlWidth: CGFloat = 83
        static let pageControlHeight: CGFloat = 12
        static let statusTextHeight: CGFloat = 32

        static func maxDots(for totalPages: Int) -> Int {
            if totalPages < 6 {
                return totalPages
            } else {
                return 6
            }
        }

        static func centerDots(for totalPages: Int) -> Int {
            if totalPages < 4 {
                return totalPages
            } else {
                return 3
            }
        }
        static let dotSize: CGFloat = 8
    }
}
