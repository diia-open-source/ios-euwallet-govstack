import Foundation
import DiiaMVPModule
import DiiaCommonTypes
import WalletScannerBarcode
import WalletCore
import WalletDomainModels

class WalletQRScannerHelper: NSObject, QRScannerDelegate {
    /// Defense-in-depth scheme allowlist applied before the `DeeplinksRoutersList`
    /// lookup. The list mirrors `WalletDeeplinkRouteBuilder`'s sharing +
    /// issuance schemes; if a future router is added with an overly-broad
    /// `canCreateRoute`, scanned codes with unknown schemes still get rejected.
    private static let allowedSchemes: Set<String> = [
        "eudi-openid4vp", "mdoc-openid4vp", "mdl-openid4vp",
        "openid4vp", "haip-vp", "haip",
        "openid-credential-offer", "haip-vci"
    ]

    private weak var presentingView: BaseView?

    init(presentingView: BaseView?) {
        self.presentingView = presentingView
        super.init()
    }

    func process(code: String, in view: BaseView?) -> QRScannerResult {
        return processUrl(code: code, in: view)
    }

    private func processUrl(code: String, in view: BaseView?) -> QRScannerResult {
        let scheme = URL(string: code)?.scheme
        guard let scheme, Self.allowedSchemes.contains(scheme) else {
            return .error(message: R.Strings.qr_incorrect_code.localized())
        }

        guard let routerFabric = DeeplinksRoutersList.userRouters.first(where: { $0.canCreateRoute(with: code) }),
              let deeplinkRouter = routerFabric.create(with: code)
        else {
            return .error(message: R.Strings.qr_incorrect_code.localized())
        }

        if let view {
            deeplinkRouter.route(in: view)
            return .success(removeScannerFromStack: shouldRemoveScannerFromStack(scannerView: view, presentingView: presentingView))
        } else if let presentingView {
            deeplinkRouter.route(in: presentingView)
            return .success(removeScannerFromStack: false)
        }

        return .success(removeScannerFromStack: false)
    }

    private func shouldRemoveScannerFromStack(scannerView: BaseView?, presentingView: BaseView?) -> Bool {
        guard let scannerView, let presentingView else {
            return false
        }

        return scannerView !== presentingView
    }
}
