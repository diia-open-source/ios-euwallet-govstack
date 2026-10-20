import UIKit

/// Generic "permission denied — open Settings" alert presenter.
///
/// iOS will not re-show its native permission prompt once the user has chosen `.denied`; the only way back is to go to Settings. This helper presents the standard 2-button alert flow (Open Settings / Cancel) and deep-links via `UIApplication.openSettingsURLString` when the user taps Open Settings.
///
/// All button + title strings are passed in by the caller — no localization happens here so the presenter stays usable from any package (WalletScannerBarcode, future mic/photo/BLE permission flows, etc.) without dragging the host's R.Strings into a shared layer.
public enum OpenSettingsAlertPresenter {
    public static func present(
        title: String,
        message: String,
        settingsButtonTitle: String,
        cancelButtonTitle: String,
        in viewController: UIViewController? = nil,
        action: ((Bool) -> Void)? = nil
    ) {
        let vc = viewController ?? UIApplication.shared.keyWindow?.visibleViewController

        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)

        let settingsAction = UIAlertAction(title: settingsButtonTitle, style: .default) { _ in
            guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else { return }
            if UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl, completionHandler: { _ in
                    action?(false)
                })
            }
        }
        alertController.addAction(settingsAction)

        let cancelAction = UIAlertAction(title: cancelButtonTitle, style: .default) { _ in
            action?(false)
        }
        alertController.addAction(cancelAction)

        vc?.present(alertController, animated: true, completion: nil)
    }
}
