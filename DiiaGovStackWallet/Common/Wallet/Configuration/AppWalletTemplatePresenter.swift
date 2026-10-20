import Foundation
import DiiaCommonTypes
import DiiaCommonServices
import DiiaMVPModule
import WalletCore
import WalletDomainModels

/// Bridges `WalletCore`'s `WalletTemplatePresenting` to `DiiaCommonServices.TemplateHandler`.
///
/// Lets the package present template alerts without depending on `DiiaCommonServices` directly.
struct AppWalletTemplatePresenter: WalletTemplatePresenting {
    func handle(
        _ template: AlertTemplate,
        in view: BaseView,
        callback: @escaping (AlertTemplateAction) -> Void
    ) {
        TemplateHandler.handle(template, in: view, callback: callback)
    }
}
