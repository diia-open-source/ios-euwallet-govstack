
import UIKit
import ReactiveKit
import DiiaMVPModule
import DiiaCommonTypes

public protocol AuthorizationServiceProtocol: AnyObject, Logoutable {
    var authState: AuthorizationState { get set }

    var isAuthorizingByDeeplink: Bool { get set }
}

public protocol PinCodeManagerProtocol: AnyObject {
    func havePincode() -> Bool
    func setPincode(pincode: [Int])
    func checkPincode(pincode: [Int]) -> Bool
    func doesNeedPincode() -> Bool
}

public protocol Logoutable: AnyObject {
    func logout()
}
                                        
public protocol UserAuthFlowHandlerProtocol: AnyObject {
    func setUserAuthorizationFlow(_ flow: UserAuthorizationFlow)
}

public protocol AuthorizationServiceStateHandler {
    func onLoginDidFinish()
    func onLogoutDidFinish()
}

// MARK: - AuthorizationService
public final class AuthorizationService: AuthorizationServiceProtocol {

    // MARK: - Properties
    private let context: AuthorizationContext

    private var hashedPincode: String? {
        didSet {
            context.storage.saveHashedPincode(hashedPincode)
        }
    }
    
    private var token: String? {
        didSet {
            context.storage.saveAuthToken(token)
        }
    }
    
    public lazy var authState: AuthorizationState = {
        guard token != nil else { return .notAuthorized }
        return .userAuth
    }()
    
    public let userAuthSignal = PassthroughSubject<Void, Never>()
    public var isAuthorizingByDeeplink = false

    // MARK: - Public Init
    public init(context: AuthorizationContext) {
        self.context = context

        hashedPincode = context.storage.getHashedPincode()
        token = context.storage.getAuthToken()
    }
    
    public func isAuthorized() -> Bool {
        authState != .notAuthorized
    }
}

extension AuthorizationService: Logoutable {
    public func logout() {
        hashedPincode = nil
        authState = .notAuthorized
        context.storage.removeLastPincodeDate()

        context.authStateHandler.onLogoutDidFinish()

        guard let token else { return }
        context.storage.saveLogoutToken(token)
        self.token = nil
    }
}

public extension AuthorizationService {
    /// Begin an authenticated session: promote `authState` to `.userAuth` and stamp the last-pincode date so `isAuthorized()` and the foreground re-lock (`doesNeedPincode()`) go live.
    /// Set explicitly because `authState` can't derive from the token — `getAuthToken()` is a stub that always returns nil.
    /// Call on every successful PIN/biometry completion; symmetric to `logout()`. Also starts background work via `onLoginDidFinish()`.
    func login() {
        authState = .userAuth
        context.storage.saveLastPincodeDate(Date())
        context.authStateHandler.onLoginDidFinish()
    }

    /// Re-stamp the last-pincode date on backgrounding so the re-lock timer measures background duration, not total session age.
    /// No-op unless authenticated with a PIN set.
    func noteEnteredBackground() {
        guard isAuthorized(), havePincode() else { return }
        context.storage.saveLastPincodeDate(Date())
    }
}

extension AuthorizationService: PinCodeManagerProtocol {
    public func havePincode() -> Bool {
        return hashedPincode != nil
    }
    
    public func setPincode(pincode: [Int]) {
        self.hashedPincode = pincode.map { String($0) }.joined().toSHA256()
    }
    
    public func checkPincode(pincode: [Int]) -> Bool {
        return self.hashedPincode == pincode.map { String($0) }.joined().toSHA256()
    }
    
    public func doesNeedPincode() -> Bool {
        if !isAuthorized() || !havePincode() { return false }
        
        if let date: Date = context.storage.getLastPincodeDate() {
            return Date() - date >= Constants.timeForNeedPincode
        }
        return true
    }
}


// MARK: - Constants
extension AuthorizationService {
    private enum Constants {
        static let timeForNeedPincode: Double = 300
    }
}
