import Foundation
import WalletAuthorization
import WalletAuthorizationPinCode

final class ServicesProvider {
    static var shared: ServicesProvider = ServicesProvider()

    let authService: AuthorizationService = .init(context: .create())
    let biometryService: BiometryAuthServiceProtocol = BiometryAuthService(storage: BiometryStorage())

    private init() { }
}
