import Foundation

// MARK: - BiometryType

public enum BiometryType {
    case none
    case touchID
    case faceID

    public var displayName: String {
        switch self {
        case .none: return ""
        case .touchID: return "Touch ID"
        case .faceID: return "Face ID"
        }
    }

    public var iconName: String {
        switch self {
        case .none: return ""
        case .touchID: return "fingerprint"
        case .faceID: return "faceId"
        }
    }
}

// MARK: - BiometryError

public enum BiometryError: Error, LocalizedError {
    case notAvailable
    case notEnrolled
    case authenticationFailed
    case userCancelled
    case systemCancel
    case passcodeNotSet
    case biometryLockout
    case unknown(Error)

    public var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "Biometric authentication is not available on this device"
        case .notEnrolled:
            return "No biometric data is enrolled on this device"
        case .authenticationFailed:
            return "Biometric authentication failed"
        case .userCancelled:
            return "Authentication was cancelled by the user"
        case .systemCancel:
            return "Authentication was cancelled by the system"
        case .passcodeNotSet:
            return "Device passcode is not set"
        case .biometryLockout:
            return "Biometry is locked due to too many failed attempts"
        case .unknown(let error):
            return error.localizedDescription
        }
    }
}

// MARK: - BiometryStorageProtocol

public protocol BiometryStorageProtocol {
    var isBiometryEnabled: Bool { get }
    func setBiometryEnabled(_ enabled: Bool)
}

// MARK: - BiometryAuthServiceProtocol

public protocol BiometryAuthServiceProtocol {
    var isBiometryAvailable: Bool { get }
    var isBiometryEnabled: Bool { get }
    var biometryType: BiometryType { get }

    func setBiometryEnabled(_ enabled: Bool)
    func authenticateWithBiometry(completion: @escaping (Result<Void, Error>) -> Void)
}
