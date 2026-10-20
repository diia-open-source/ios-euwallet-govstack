import UIKit
import DiiaUIComponents

/// Host-side glue that supplies localized R.Strings to the generic `OpenSettingsAlertPresenter` (in DiiaUIComponents).
/// One closure per permission flow — extend with `microphonePermissionDeniedHandler`, `locationPermissionDeniedHandler`, etc., as future permissions land.
struct AccessHelper {
    /// Closure suitable for `CameraAccessChecker.askCameraAccess(permissionDeniedHandler:)`.
    static let cameraPermissionDeniedHandler: (UIViewController?, @escaping (Bool) -> Void) -> Void = { viewController, action in
        OpenSettingsAlertPresenter.present(
            title: R.Strings.permissions_camera_not_granted.localized(),
            message: R.Strings.permissions_camera_settings.localized(),
            settingsButtonTitle: R.Strings.permissions_settings.localized(),
            cancelButtonTitle: R.Strings.permissions_exit.localized(),
            in: viewController,
            action: action
        )
    }
}
