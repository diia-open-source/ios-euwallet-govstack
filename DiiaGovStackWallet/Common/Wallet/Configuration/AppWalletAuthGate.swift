import UIKit
import DiiaMVPModule
import DiiaUIComponents
import WalletAuthorizationPinCode
import WalletCore
import WalletDomainModels

/// Bridges the wallet sharing flow's pre-send PIN/biometry gate to the app's
/// `BiometryEnterPinCodeInContainerModule`.
final class AppWalletAuthGate: WalletAuthGating {
    private var pinViewController: UIViewController?

    func presentAuthBeforeSend(
        in view: BaseView,
        onSuccess: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) {
        let pinModule = BiometryEnterPinCodeInContainerModule(
            context: EnterPinCodeModuleContext.create(completionHandler: { [weak self] result in
                self?.dismissPinModule()
                switch result {
                case .success:
                    onSuccess()
                case .failure:
                    onCancel()
                }
            }),
            viewModel: .auth,
            biometryService: ServicesProvider.shared.biometryService,
            onBiometrySuccess: { [weak self] in
                self?.dismissPinModule()
                onSuccess()
            }
        )
        pinViewController = pinModule.viewController()
        view.showChild(module: pinModule)
    }

    private func dismissPinModule() {
        // Added via `showChild` as a child container, so `dismiss()` is a no-op — `ContainerProtocol.close()` is the correct teardown.
        (pinViewController as? ContainerProtocol)?.close()
        pinViewController = nil
    }
}
