import UIKit
import AVFoundation
import DiiaUIComponents

/// Asks the system for camera access and routes the outcome to `handler`.
///
/// `handler(true)` — access granted (already authorized OR user just granted on the system prompt).
/// `handler(false)` — access denied, restricted, or the user dismissed the denied-state alert without granting.
///
/// When status is `.denied`, the system will NOT re-show its prompt — only Settings can change it. `permissionDeniedHandler` is invoked so the host can surface its own "Open Settings" alert (typically via `AccessHelper.showSettingsAlert(...)` with localized strings). If `nil`, denied falls through to `handler(false)` without further UI.
/// The checker stays SDK-blind: it doesn't know about `R.Strings` or `AccessHelper` — both live in the composition root.
public enum CameraAccessChecker {
    public static func askCameraAccess(
        in viewController: UIViewController? = nil,
        permissionDeniedHandler: ((UIViewController?, @escaping (Bool) -> Void) -> Void)? = nil,
        handler: @escaping (Bool) -> Void
    ) {
        let cameraPermissionStatus = AVCaptureDevice.authorizationStatus(for: .video)

        switch cameraPermissionStatus {
        case .authorized:
            handler(true)
        case .denied:
            if let permissionDeniedHandler {
                permissionDeniedHandler(viewController, handler)
            } else {
                handler(false)
            }
        case .restricted:
            handler(false)
        default:
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { (granted: Bool) -> Void in
                onMainQueue {
                    handler(granted)
                }
            })
        }
    }
}
