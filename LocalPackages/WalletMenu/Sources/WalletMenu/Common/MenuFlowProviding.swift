import Foundation
import DiiaMVPModule

/// App-supplied routing for the menu + settings flows.
///
/// Lets `WalletMenu` stay free of app-target glue: the host app composes the actual
/// camera-access checks, logout pathway, and onward navigation to docs reorder /
/// change-PIN sub-flows.
public protocol MenuFlowProviding: AnyObject {
    func presentQRScanner(in view: BaseView)
    func performLogout()
    func openDocsOrder(in view: BaseView)
    func openChangePin(in view: BaseView)
}
