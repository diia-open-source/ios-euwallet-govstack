import UIKit
import DiiaMVPModule
import DiiaUIComponents

/// A wrapper module that adds biometry support to the standard EnterPinCodeModule
public final class BiometryEnterPinCodeModule: BaseModule {
    private let containerViewController: BiometryEnterPinCodeContainerViewController

    public init(
        context: EnterPinCodeModuleContext,
        viewModel: EnterPinCodeViewModel,
        biometryService: BiometryAuthServiceProtocol,
        onBiometrySuccess: @escaping () -> Void
    ) {
        let pinCodeModule = EnterPinCodeModule(context: context, viewModel: viewModel)
        containerViewController = BiometryEnterPinCodeContainerViewController(
            pinCodeModule: pinCodeModule,
            biometryService: biometryService,
            storage: context.storage,
            onBiometrySuccess: onBiometrySuccess
        )
    }

    public func viewController() -> UIViewController {
        return containerViewController
    }
}

/// A wrapper module for displaying in container (overlay)
public final class BiometryEnterPinCodeInContainerModule: BaseModule {
    private let container: ChildContainerViewController

    public init(
        context: EnterPinCodeModuleContext,
        viewModel: EnterPinCodeViewModel,
        biometryService: BiometryAuthServiceProtocol,
        onBiometrySuccess: @escaping () -> Void
    ) {
        let pinCodeModule = EnterPinCodeModule(context: context, viewModel: viewModel)
        let contentViewController = BiometryEnterPinCodeContainerViewController(
            pinCodeModule: pinCodeModule,
            biometryService: biometryService,
            storage: context.storage,
            onBiometrySuccess: onBiometrySuccess
        )

        let childContainer = ChildContainerViewController()
        childContainer.childSubview = contentViewController
        childContainer.presentationStyle = .fullscreen
        container = childContainer
    }

    public func viewController() -> UIViewController {
        return container
    }
}

// MARK: - Container View Controller
public final class BiometryEnterPinCodeContainerViewController: UIViewController, ChildSubcontroller {

    // MARK: - Properties
    public weak var container: ContainerProtocol?
    private let pinCodeModule: EnterPinCodeModule
    private let biometryService: BiometryAuthServiceProtocol
    private let storage: PinCodeStorageProtocol
    private let onBiometrySuccess: () -> Void
    private var hasPresentedBiometry = false

    // MARK: - Initialization
    init(
        pinCodeModule: EnterPinCodeModule,
        biometryService: BiometryAuthServiceProtocol,
        storage: PinCodeStorageProtocol,
        onBiometrySuccess: @escaping () -> Void
    ) {
        self.pinCodeModule = pinCodeModule
        self.biometryService = biometryService
        self.storage = storage
        self.onBiometrySuccess = onBiometrySuccess
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    override public func viewDidLoad() {
        super.viewDidLoad()
        setupChildViewController()
        setupBiometryButton()
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Automatically trigger biometry on first appearance if enabled
        if !hasPresentedBiometry && biometryService.isBiometryEnabled {
            hasPresentedBiometry = true
            // Small delay to ensure UI is ready
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.authenticateWithBiometry()
            }
        }
    }

    override public func canGoBack() -> Bool {
        return false
    }

    // MARK: - Setup
    private func setupChildViewController() {
        let childVC = pinCodeModule.viewController()
        addChild(childVC)
        view.addSubview(childVC.view)
        childVC.view.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            childVC.view.topAnchor.constraint(equalTo: view.topAnchor),
            childVC.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            childVC.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            childVC.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        childVC.didMove(toParent: self)
    }

    private func setupBiometryButton() {
        guard biometryService.isBiometryEnabled else { return }

        let biometryType = biometryService.biometryType
        guard biometryType != .none else { return }

        // Get the appropriate icon
        let symbolConfig = UIImage.SymbolConfiguration(weight: .thin)
        let icon = UIImage(named: biometryType.iconName, in: Bundle.module, compatibleWith: nil)
            ?? UIImage(systemName: biometryType == .faceID ? "faceid" : "touchid", withConfiguration: symbolConfig)

        // Configure the built-in biometry button in PincodeView
        pinCodeModule.configureAdditionalButton(
            image: icon,
            accessibilityLabel: biometryType.displayName,
            accessibilityHint: R.Strings.biometry_accessibility_button_hint.localized(with: biometryType.displayName)
        ) { [weak self] in
            self?.authenticateWithBiometry()
        }
    }

    // MARK: - Private Methods
    private func authenticateWithBiometry() {
        biometryService.authenticateWithBiometry { [weak self] result in
            switch result {
            case .success:
                // Biometry success is equivalent to a correct PIN, so clear the failed-attempt counter — the PIN-entry path resets it too, but biometry bypasses that presenter.
                self?.storage.saveIncorrectPincodeAttemptsCount(0)
                self?.onBiometrySuccess()
            case .failure:
                // Biometry failures (including user cancellation) leave the user on the PIN screen.
                break
            }
        }
    }
}
