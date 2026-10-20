import UIKit
import DiiaMVPModule

public protocol BiometrySetupAction: BasePresenter {
    func allowTapped()
    func maybeLaterTapped()
}

final class BiometrySetupPresenter: BiometrySetupAction {

    // MARK: - Properties
    unowned var view: BiometrySetupView
    private let biometryService: BiometryAuthServiceProtocol
    private let onComplete: () -> Void

    // MARK: - Init
    init(
        view: BiometrySetupView,
        biometryService: BiometryAuthServiceProtocol,
        onComplete: @escaping () -> Void
    ) {
        self.view = view
        self.biometryService = biometryService
        self.onComplete = onComplete
    }

    // MARK: - BiometrySetupAction
    func configureView() {
        let biometryType = biometryService.biometryType
        let biometryName = biometryType.displayName

        let symbolConfig = UIImage.SymbolConfiguration(weight: .thin)
        let icon = UIImage(named: biometryType.iconName, in: Bundle.module, compatibleWith: nil)
            ?? UIImage(systemName: biometryType == .faceID ? "faceid" : "touchid", withConfiguration: symbolConfig)

        let viewModel = BiometrySetupViewModel(
            title: R.Strings.biometry_setup_title.localized(with: biometryName),
            description: R.Strings.biometry_setup_description.localized(with: biometryName),
            icon: icon
        )

        view.configure(with: viewModel)
    }

    func allowTapped() {
        biometryService.authenticateWithBiometry { [weak self] result in
            guard let self else { return }
            switch result {
            case .success:
                self.biometryService.setBiometryEnabled(true)
                self.onComplete()
            case .failure(let error):
                if let biometryError = error as? BiometryError,
                   case .userCancelled = biometryError {
                    // User cancelled, stay on screen
                } else {
                    self.view.showError(message: error.localizedDescription)
                }
            }
        }
    }

    func maybeLaterTapped() {
        biometryService.setBiometryEnabled(false)
        onComplete()
    }
}
