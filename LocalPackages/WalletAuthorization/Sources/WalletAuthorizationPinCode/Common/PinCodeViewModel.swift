
import Foundation
import DiiaMVPModule
import WalletAuthorization
import DiiaCommonTypes

public final class PinCodeViewModel {
    let pinCodeLength: Int
    let createDetails: String
    let repeatDetails: String
    let completionHandler: ([Int], BaseView) -> Void
    
    public init(
        pinCodeLength: Int,
        createDetails: String,
        repeatDetails: String,
        completionHandler: @escaping ([Int], BaseView) -> Void
    ) {
        self.pinCodeLength = pinCodeLength
        self.createDetails = createDetails
        self.repeatDetails = repeatDetails
        self.completionHandler = completionHandler
    }
}
