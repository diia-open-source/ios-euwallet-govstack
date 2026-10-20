import Foundation
import WalletAuthorizationPinCode
import DiiaMVPModule
import WalletAppStorage

extension EnterPinCodeModuleContext {

    static func create(completionHandler: @escaping (Result<String, Error>) -> Void) -> EnterPinCodeModuleContext {
        let delegate: EnterPinCodeDelegate = EnterPinCodeAuthDelegate(completionHandler: completionHandler)
        let storage = PinCodeStorage(storage: StoreHelper.instance)
        return EnterPinCodeModuleContext(storage: storage, enterPinCodeDelegate: delegate)
    }
}
