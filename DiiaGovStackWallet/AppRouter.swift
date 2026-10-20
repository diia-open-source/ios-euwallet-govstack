import UIKit
import DiiaMVPModule
import DiiaUIComponents
import DiiaCommonTypes
import WalletAuthorization
import WalletAuthorizationPinCode
import WalletScannerBarcode
import WalletAppStorage
import WalletCore
import WalletDomainModels

class AppRouter {

    private var window: UIWindow!
    private var navigationController: UINavigationController!
    private var tabBarController: MainTabRoutingProtocol?

    private var pincodeContainer: ContainerProtocol?
    private var pincodeView: UIViewController?
    private var defferedAction: ((BaseView?) -> Void)?
    private var defferedSafeAction: ((BaseView?) -> Void)?

    var didFinishStarting: Bool = false {
        didSet {
            guard didFinishStarting else { return }
            self.defferedAction?(self.currentView())
            self.defferedAction = nil
        }
    }
    var didFinishStartingWithPincode: Bool = false {
        didSet {
            guard didFinishStartingWithPincode else { return }
            self.defferedSafeAction?(self.currentView())
            self.defferedSafeAction = nil
        }
    }
    private let storeHelper: StoreHelperProtocol = StoreHelper.instance

    static let instance = AppRouter()
    
    private init() {}
    
    func configure(window: UIWindow, navigationController: UINavigationController = BaseNavigationController()) {
        self.window = window
        navigationController.setNavigationBarHidden(true, animated: false)
        self.navigationController = navigationController
    }
    
    func start() {
        self.window.rootViewController = navigationController
        self.window.makeKeyAndVisible()
        self.didFinishStartingWithPincode = false
        self.didFinishStarting = false
        self.tabBarController = nil
        // Clear stale overlay refs — a leftover `pincodeContainer` would block `showPincode()` on the next re-lock.
        self.pincodeContainer = nil
        self.pincodeView = nil

        routeStart()
        didFinishStarting = true
    }

    /// Drops any deeplink deferred behind the PIN gate.
    /// Called on logout so a sharing/issuance link queued in the previous session can't auto-fire after the next PIN setup re-arms `didFinishStartingWithPincode`.
    /// NOT done on a normal launch — a deeplink that cold-launches the wallet is deferred during the splash and must survive `start()` so it runs once the user authenticates.
    func clearDeferredActions() {
        self.defferedAction = nil
        self.defferedSafeAction = nil
    }

    /// Navigate to destination module or make it root in navigation. Start deffered action if needed
    /// - Parameters:
    ///   - module: Destination module
    ///   - needPincode: Define if user need authorization for this navigation
    ///   - asRoot: Define if destination module should be root controller in navigation. If true rewrite tabBarController
    func open(module: BaseModule, needPincode: Bool, asRoot: Bool = false) {
        if needPincode {
            let completion: (Result<String, Error>) -> Void = { [weak self] result in
                guard let self = self, case .success = result else { return }

                ServicesProvider.shared.authService.login()
                self.forceOpen(module: module, asRoot: asRoot, completion: { [weak self] in
                    self?.pincodeView = nil
                    self?.didFinishStartingWithPincode = true
                })
            }

            let biometryService = ServicesProvider.shared.biometryService
            let onBiometrySuccess: () -> Void = { [weak self] in
                guard let self = self else { return }
                ServicesProvider.shared.authService.login()
                self.forceOpen(module: module, asRoot: asRoot, completion: { [weak self] in
                    self?.pincodeView = nil
                    self?.didFinishStartingWithPincode = true
                })
            }
            
            let pincodeView = BiometryEnterPinCodeModule(
                context: EnterPinCodeModuleContext.create(completionHandler: completion),
                viewModel: .auth,
                biometryService: biometryService,
                onBiometrySuccess: onBiometrySuccess
            ).viewController()
            self.pincodeView = pincodeView
            navigationController.pushViewController(pincodeView, animated: true)
            return
        } else {
            forceOpen(module: module, asRoot: asRoot, completion: nil)
        }
    }
    
    /// Returns current visible view
    func currentView() -> BaseView? {
        return window.visibleViewController as? BaseView
    }
    
    /// Shows pincode over currentModule
    func showPincode() {
        if pincodeView != nil || pincodeContainer != nil { return }
        // Bail when there's no host view — otherwise `pincodeContainer` stays set and permanently blocks future re-locks.
        guard let currentView = currentView() else { return }
        didFinishStartingWithPincode = false
        let completion: (Result<String, Error>) -> Void = { [weak self] result in
            guard let self = self, case .success = result else { return }
            ServicesProvider.shared.authService.login()
            self.pincodeContainer?.close()
            self.pincodeContainer = nil
            self.didFinishStartingWithPincode = true
        }

        let biometryService = ServicesProvider.shared.biometryService
        let onBiometrySuccess: () -> Void = { [weak self] in
            guard let self = self else { return }
            ServicesProvider.shared.authService.login()
            self.pincodeContainer?.close()
            self.pincodeContainer = nil
            self.didFinishStartingWithPincode = true
        }
        
        let module = BiometryEnterPinCodeInContainerModule(
            context: EnterPinCodeModuleContext.create(completionHandler: completion),
            viewModel: .auth,
            biometryService: biometryService,
            onBiometrySuccess: onBiometrySuccess
        )
        currentView.showChild(module: module)
        pincodeContainer = module.viewController() as? ChildContainerViewController
    }
    
    /// Perform navigation action with currentView if route start processing was finished. If not, save it and process after finishing
    /// - Parameters:
    ///   - action: Navigation callback with view parameter which is currentView of AppRouter
    ///   - needPincode: Define if user need authorization for this navigation
    func performOrDefer(action: @escaping ((BaseView?) -> Void), needPincode: Bool = false) {
        if didFinishStarting
            && (!needPincode || didFinishStartingWithPincode) {
            action(currentView())
        } else if !needPincode {
            defferedAction = action
        } else {
            defferedSafeAction = action
        }
    }
    
    /// Pops to Root tab controller if it exists
    /// - Parameter action: Action for processing in tab controller after popping
    func popToTab(with action: MainTabAction) {
        if let tabController = self.tabBarController {
            navigationController.popToViewController(tabController, animated: true)
            tabController.processAction(action: action)
        }
    }
    
    // MARK: - Private
    private func routeStart() {
        func preparePinCodeModule() -> CreatePinCodeModule {
            return CreatePinCodeModule(
                    viewModel: PinCodeViewModel(
                    pinCodeLength: AppConstants.defaultPinCodeLength,
                    createDetails: R.Strings.authorization_new_pin_details.localized(),
                    repeatDetails: R.Strings.authorization_repeat_pin_details.localized(),
                    completionHandler: { (pincode, view) in
                        ServicesProvider.shared.authService.setPincode(pincode: pincode)
                        ServicesProvider.shared.authService.login()

                        // Check if biometry is available and show setup prompt
                        let biometryService = ServicesProvider.shared.biometryService
                        if biometryService.isBiometryAvailable {
                            let biometrySetupModule = BiometrySetupModule(
                                biometryService: biometryService,
                                onComplete: {
                                    AppRouter.instance.open(
                                        module: MainTabBarModule(qrCodeScannerModuleFactory: QRCodeScannerModuleFactory(images: .default)),
                                        needPincode: false,
                                        asRoot: true
                                    )
                                    AppRouter.instance.didFinishStartingWithPincode = true
                                }
                            )
                            AppRouter.instance.open(module: biometrySetupModule, needPincode: false)
                        } else {
                            AppRouter.instance.open(
                                module: MainTabBarModule(qrCodeScannerModuleFactory: QRCodeScannerModuleFactory(images: .default)),
                                needPincode: false,
                                asRoot: true
                            )
                            AppRouter.instance.didFinishStartingWithPincode = true
                        }
                    }
                )
            )
        }
        
        if ServicesProvider.shared.authService.havePincode() {
            open(
                module: MainTabBarModule(qrCodeScannerModuleFactory: QRCodeScannerModuleFactory(images: .default)),
                needPincode: true,
                asRoot: true
            )
        } else {
            open(module: preparePinCodeModule(), needPincode: false)
        }
    }
    
    private func forceOpen(module: BaseModule, asRoot: Bool, completion: Callback?) {
        if asRoot {
            let rootViewController = module.viewController()
            tabBarController = rootViewController as? MainTabRoutingProtocol
            navigationController.setViewControllers([rootViewController], animated: true, completion: completion)

            // Install the deferred-issuance alert gate now that the tab bar is
            // on screen. Polling itself was already started in
            // `AuthorizationStateHandler.onLoginDidFinish` via
            // `WalletDependencies.walletLifecycle.startSession()`. Per product
            // requirement, deferred-completion alerts only appear when the user
            // is parked on the Documents tab at its nav root with no modal up
            // — `documentsTabRootIfForeground()` encodes that gate; returning
            // nil suppresses the alert silently for the current poll.
            WalletDependencies.walletLifecycle.alertHostProvider = { [weak self] in
                return self?.tabBarController?.documentsTabRootIfForeground()
            }
        } else {
            self.navigationController.pushViewController(module.viewController(), animated: true, completion: completion)
        }
    }
}

extension AppRouter: AppRouterProtocol {}
