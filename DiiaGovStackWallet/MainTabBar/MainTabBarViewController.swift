import UIKit
import Lottie
import DiiaMVPModule
import DiiaUIComponents

typealias UnreadTabBarItem = (index: Int, isAvailable: Bool)

protocol MainTabRoutingProtocol: UIViewController {
    func processAction(action: MainTabAction)
    /// Returns the foreground `BaseView` only when the user is currently parked
    /// on the **Documents** tab AND at that tab's nav root AND no modal is
    /// presented over the tab bar.
    ///
    /// Returns `nil` in every other state — Menu tab selected, deeper nav (Add
    /// Document, Change Order, …), modal sheet (QR scanner). Used by the
    /// deferred-issuance alert gate so completion alerts only surface when the
    /// user can actually see the document they were waiting on.
    func documentsTabRootIfForeground() -> BaseView?
}

protocol MainTabBarView: BaseView {
    func updateView()
    func setupCurrentController(_ viewController: UIViewController)
    func setupSelectedItem(index: Int, haveUnreadItem: UnreadTabBarItem?)
    func updateBottomColor(tabColor: TabBarColor)
    func onSameSelected()
    func processChildAction(action: String)
    func setBackground(background: TabBarBackground)
}

enum TabBarColor {
    case fixed(colorHex: String)
    case adaptive
}

enum TabBarBackground {
    case image(image: UIImage?)
    case animation(name: String)
    case clear
}

final class MainTabBarViewController: UIViewController {

    // MARK: - Views
    private let backgroundAnimationView: LottieAnimationView = {
        let view = LottieAnimationView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .systemBackground
        return view
    }()

    private let backgroundImageView: UIImageView = {
        let view = UIImageView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.contentMode = .scaleToFill
        view.clipsToBounds = true
        view.isUserInteractionEnabled = false
        view.image = UIImage(named: Constants.initialBackgroundImageName)
        return view
    }()

    private let containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        return view
    }()

    private let bottomView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .systemBackground
        return view
    }()

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = Constants.collectionMinimumLineSpacing
        layout.minimumInteritemSpacing = Constants.collectionMinimumInteritemSpacing
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.backgroundColor = .clear
        cv.clipsToBounds = true
        cv.dataSource = self
        cv.delegate = self
        cv.register(MainTabCollectionCell.self, forCellWithReuseIdentifier: MainTabCollectionCell.reuseID)
        return cv
    }()

    // MARK: - Properties
    var presenter: MainTabBarAction!
    private var bottomColorObservation: NSKeyValueObservation?
    private var topColorObservation: NSKeyValueObservation?

    private var currentChild: UIViewController?
    private var currentIndex: Int = 0

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupLayout()
        presenter.configureView()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        presenter.updateSelectionIfNeed(for: currentIndex)
    }

    // MARK: - Overriding
    override func canGoBack() -> Bool {
        return false
    }

    // MARK: - Setup
    private func setupLayout() {
        view.addSubview(backgroundAnimationView)
        view.addSubview(backgroundImageView)
        view.addSubview(containerView)
        view.addSubview(bottomView)
        view.addSubview(collectionView)

        let safeArea = view.safeAreaLayoutGuide

        NSLayoutConstraint.activate([
            // Background animation — fills view top to bottom, edges to safe area
            backgroundAnimationView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundAnimationView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            backgroundAnimationView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor),
            backgroundAnimationView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor),

            // Background image — same as animation
            backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor),

            // Container — from view top down to tab bar top
            containerView.topAnchor.constraint(equalTo: view.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: collectionView.topAnchor),

            // Collection view — pinned to safe area bottom, fixed height
            collectionView.heightAnchor.constraint(equalToConstant: Constants.tabBarHeight),
            collectionView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor),

            // Bottom backdrop — from tab bar top down to view bottom (covers home indicator area)
            bottomView.topAnchor.constraint(equalTo: containerView.bottomAnchor),
            bottomView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor),
            bottomView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor),
            bottomView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}

// MARK: - View logic
extension MainTabBarViewController: MainTabBarView {
    func setupCurrentController(_ viewController: UIViewController) {
        if currentChild == viewController { return }
        if let oldVC = currentChild {
            VCChildComposer.removeChild(oldVC, from: self, animationType: .none)
        }

        VCChildComposer.addChild(viewController, to: self, in: containerView, animationType: .none)

        currentChild = viewController
    }

    func setupSelectedItem(index: Int, haveUnreadItem: UnreadTabBarItem?) {
        currentIndex = index
        for indexPath in collectionView.indexPathsForVisibleItems {
            if let cell = collectionView.cellForItem(at: indexPath) as? MainTabCollectionCell {
                configureCell(cell,
                              cellForItemAt: indexPath,
                              selectedIndex: index,
                              haveUnreadItem: haveUnreadItem)
            }
        }
    }

    func updateView() {
        collectionView.reloadData()
    }

    func updateBottomColor(tabColor: TabBarColor) {
        switch tabColor {
        case .fixed(let color):
            bottomColorObservation = nil
            bottomView.backgroundColor = UIColor(color)
        case .adaptive:
            bottomColorObservation = currentChild?.view.observe(\.backgroundColor, onChange: { [weak self] (color) in
                self?.bottomView.backgroundColor = color
            })
        }
    }

    func onSameSelected() {
        guard let currentController = currentChild as? MainEmbeddable else { return }

        currentController.onSameSelected()
    }

    func processChildAction(action: String) {
        guard let currentController = currentChild as? MainEmbeddable else { return }

        currentController.processAction(action: action)
    }

    func setBackground(background: TabBarBackground) {
        switch background {
        case .image(let image):
            guard let image = image else { return }
            backgroundImageView.isHidden = false
            backgroundImageView.image = image
            backgroundAnimationView.isHidden = true
        case .animation(let name):
            backgroundImageView.isHidden = true
            backgroundAnimationView.isHidden = false
            backgroundAnimationView.animation = .named(name)
            backgroundAnimationView.loopMode = .loop
            backgroundAnimationView.backgroundBehavior = .pauseAndRestore
            backgroundAnimationView.contentMode = .scaleAspectFill
            backgroundAnimationView.play()
        case .clear:
            backgroundImageView.isHidden = true
            backgroundAnimationView.isHidden = true
        }
    }
}

extension MainTabBarViewController: MainTabRoutingProtocol {
    func processAction(action: MainTabAction) {
        presenter.processAction(action: action)
    }

    func documentsTabRootIfForeground() -> BaseView? {
        // Documents tab sits at index 0 in `MainTabBarPresenter.tabs`
        // (`[.documents, .menu]`). The presenter doesn't expose a tab-kind
        // accessor; keep the assumption with the constant and revisit if the
        // tab order ever changes.
        let documentsTabIndex = 0
        guard currentIndex == documentsTabIndex else { return nil }
        // Suppress while a modal sheet is up over the tab bar (QR scanner,
        // PIN gate, etc.).
        guard presentedViewController == nil else { return nil }

        guard let tabRoot = currentChild else { return nil }
        if let nav = tabRoot as? UINavigationController {
            // Pushed deeper into the tab (Add Document, Change Order, …): no alert.
            guard nav.viewControllers.count == 1, nav.presentedViewController == nil else {
                return nil
            }
            return nav.topViewController as? BaseView
        }
        return tabRoot as? BaseView
    }
}

// MARK: - Collection View Methods
extension MainTabBarViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return presenter.numberOfItems()
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let vm = presenter.itemAt(with: indexPath.item) else { return UICollectionViewCell() }

        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MainTabCollectionCell.reuseID, for: indexPath) as? MainTabCollectionCell {
            cell.configure(with: vm)
            configureCell(cell,
                          cellForItemAt: indexPath,
                          selectedIndex: currentIndex,
                          haveUnreadItem: presenter.getUnreadMessagesItemStatus())

            return cell
        }
        return UICollectionViewCell()
    }
}

// MARK: - UICollectionViewDelegate
extension MainTabBarViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        presenter.selectItem(at: indexPath.item)
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension MainTabBarViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width / CGFloat(presenter.numberOfItems()), height: collectionView.frame.height)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
}

// MARK: - Private methods
private extension MainTabBarViewController {
    func configureCell(_ cell: MainTabCollectionCell,
                       cellForItemAt indexPath: IndexPath,
                       selectedIndex: Int,
                       haveUnreadItem: UnreadTabBarItem?) {
        cell.setSelected(isSelected: indexPath.item == selectedIndex)
        cell.configureAccessibility(isSelected: indexPath.item == selectedIndex,
                                    currentValue: indexPath.item + 1,
                                    totalValue: presenter.numberOfItems(),
                                    haveUnreadItem: indexPath.item == haveUnreadItem?.index ? haveUnreadItem?.isAvailable : nil)
    }
}

// MARK: - Constants
private extension MainTabBarViewController {
    enum Constants {
        static let tabBarHeight: CGFloat = 70
        static let collectionMinimumLineSpacing: CGFloat = 10
        static let collectionMinimumInteritemSpacing: CGFloat = 10
        static let initialBackgroundImageName = "ukrainianGradient"
    }
}
