import Foundation
import DiiaMVPModule

public enum QRScannerResult {
    case none
    case error(message: String)
    case success(removeScannerFromStack: Bool)
}

public protocol QRScannerDelegate: NSObjectProtocol {
    func process(code: String, in view: BaseView?) -> QRScannerResult
}

/// App-supplied factory for the QR code scanner module.
///
/// Wallet packages take this protocol via init so they don't pin a specific
/// scanner implementation. The host app conforms its concrete factory and
/// passes it through.
public protocol QRCodeScannerModuleFactoryProtocol {
    func make(delegate: QRScannerDelegate?) -> BaseModule
}
