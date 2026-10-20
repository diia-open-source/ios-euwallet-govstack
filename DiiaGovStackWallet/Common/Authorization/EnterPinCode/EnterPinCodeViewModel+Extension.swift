import Foundation
import WalletAuthorizationPinCode

// MARK: - Factory
extension EnterPinCodeViewModel {
    static let auth = EnterPinCodeViewModel(
        pinCodeLength: AppConstants.defaultPinCodeLength,
        title: R.Strings.authorization_enter_pin_title.localized(),
        forgotTitle: R.Strings.authorization_dont_remember_pin.localized()
    )
}
