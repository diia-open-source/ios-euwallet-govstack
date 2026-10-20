import UIKit
import DiiaMVPModule
import WalletDocumentsCommonTypes
import WalletDocumentsCore
import DiiaUIComponents
import WalletCore
import WalletDomainModels
import WalletScannerBarcode
import WalletTransaction
import WalletMenu

protocol MainTabBarAction: BasePresenter {
    func numberOfItems() -> Int
    func itemAt(with index: Int) -> SelectableIconTitleViewModel?
    func selectItem(at index: Int)
    func updateSelectionIfNeed(for currentIndex: Int)
    func topButtonClicked()
    func processAction(action: MainTabAction)
    func getUnreadMessagesItemStatus() -> UnreadTabBarItem?
}

private enum TabType {
    case documents(view: UIViewController)
    case menu(view: UIViewController)

    func isSameForAction(_ action: MainTabAction) -> Bool {
        switch self {
        case .documents:
            switch action {
            case .documents:
                return true
            default:
                return false
            }
        case .menu:
            return action == .settings
        }
    }
}

final class MainTabBarPresenter: NSObject, MainTabBarAction {
    unowned var view: MainTabBarView
    private var currentIndex: Int?
    
    private var haveUnreadMessages = false {
        didSet {
            view.updateView()
        }
    }

    private var tabs: [TabType] = []
    private let qrCodeScannerModuleFactory: QRCodeScannerModuleFactoryProtocol
    private let qrHelper: WalletQRScannerHelper

    // MARK: - Init
    init(view: MainTabBarView, qrCodeScannerModuleFactory: QRCodeScannerModuleFactoryProtocol) {
        self.view = view
        self.qrCodeScannerModuleFactory = qrCodeScannerModuleFactory
        qrHelper = WalletQRScannerHelper(presentingView: view)
    }
    
    func configureView() {
        tabs = [
            .documents(view: DocumentsCollectionModule(
                context: DocumentsCollectionContextImpl(
                    qrCodeScannerModuleFactory: qrCodeScannerModuleFactory
                ),
                viewStateFactory: DocumentsCollectionViewStateFactory(),
                actionFabric: DocumentActionsFabric()
            ).viewController()),
            .menu(view: MenuModule(
                view: ConstructorViewController(),
                viewStateFactory: MenuViewStateFactory(),
                transactionLogStorage: AppConfigurator.transactionLogController.transactionLogStorage,
                transactionsViewStateFactory: TransactionsViewStateFactory(),
                flowProvider: AppMenuFlowProvider(qrCodeScannerModuleFactory: qrCodeScannerModuleFactory),
                biometryService: ServicesProvider.shared.biometryService,
                backgroundImage: R.image.light_background.image
            ).viewController())
        ]
        
        view.updateBottomColor(tabColor: .fixed(colorHex: AppConstants.Colors.black))
    }
    
    func topButtonClicked() {
        CameraAccessChecker.askCameraAccess(permissionDeniedHandler: AccessHelper.cameraPermissionDeniedHandler) {[weak self] (granted) in
            guard granted, let self else { return }
            self.view.open(module: self.qrCodeScannerModuleFactory.make(delegate: self.qrHelper))
        }
    }
    
    func updateSelectionIfNeed(for currentIndex: Int) {
        if currentIndex == self.currentIndex {
            return
        }
        selectItem(at: currentIndex)
    }
    
    func numberOfItems() -> Int {
        return tabs.count
    }
    
    func itemAt(with index: Int) -> SelectableIconTitleViewModel? {
        guard tabs.indices.contains(index) else { return nil }
        
        switch tabs[index] {
        case .documents:
            return SelectableIconTitleViewModel(
                iconName: R.image.menuDocumentsInactive.name,
                title: R.Strings.main_screen_documents.localized(),
                selectedIconName: R.image.menuDocumentsActive.name
            )
        case .menu:
            return SelectableIconTitleViewModel(
                iconName: R.image.menuSettingsInactive.name,
                title: R.Strings.main_screen_menu.localized(),
                selectedIconName: R.image.menuSettingsActive.name
            )
        }
    }
    
    func selectItem(at index: Int) {
        guard tabs.indices.contains(index) else { return }
        if currentIndex == index {
            view.onSameSelected()
            return
        }
        currentIndex = index
        
        switch tabs[index] {
        case .documents(let viewController):
            view.setupCurrentController(viewController)
            view.setBackground(background: .animation(name: "background_gradient"))
        case .menu(let viewController):
            view.setupCurrentController(viewController)
            view.setBackground(background: .image(image: R.image.light_background.image))
        }
        view.setupSelectedItem(index: index, haveUnreadItem: getUnreadMessagesItemStatus())
    }
    
    func processAction(action: MainTabAction) {
        if let newIndex = tabs.firstIndex(where: { $0.isSameForAction(action) }),
           currentIndex != newIndex {
            selectItem(at: newIndex)
        }
        switch action {
        case .documents(let type):
            if let docType = type?.rawValue {
                view.processChildAction(action: docType)
            }
        default: break
        }
    }
    
    func getUnreadMessagesItemStatus() -> UnreadTabBarItem? {
        if let haveUnreadItemIndex = tabs.firstIndex(where: { item in
            if case .menu = item { return true }
            return false
        }) {
            return (haveUnreadItemIndex, haveUnreadMessages)
        }
        return nil
    }
}

extension MainTabBarPresenter: DocumentCollectionHolderProtocol {
    func updateBackgroundImage(image: UIImage?) {
        guard let image = image else { return }
        view.setBackground(background: .image(image: image))
    }
}
