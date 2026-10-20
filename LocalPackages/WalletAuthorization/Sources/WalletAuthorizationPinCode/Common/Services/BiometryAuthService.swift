import Foundation
import LocalAuthentication

public final class BiometryAuthService: BiometryAuthServiceProtocol {

    // MARK: - Properties
    private let storage: BiometryStorageProtocol

    // MARK: - Initialization
    public init(storage: BiometryStorageProtocol) {
        self.storage = storage
    }

    // MARK: - BiometryAuthServiceProtocol
    public var isBiometryAvailable: Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }

    public var isBiometryEnabled: Bool {
        guard isBiometryAvailable else { return false }
        return storage.isBiometryEnabled
    }

    public var biometryType: BiometryType {
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }

        switch context.biometryType {
        case .touchID:
            return .touchID
        case .faceID:
            return .faceID
        case .opticID:
            // Optic ID (Vision Pro) — mapped to faceID as the closest equivalent.
            return .faceID
        case .none:
            return .none
        @unknown default:
            return .none
        }
    }

    public func setBiometryEnabled(_ enabled: Bool) {
        storage.setBiometryEnabled(enabled)
    }

    public func authenticateWithBiometry(completion: @escaping (Result<Void, Error>) -> Void) {
        let context = LAContext()
        context.localizedFallbackTitle = R.Strings.authorization_biometry_fallback_title.localized()

        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            DispatchQueue.main.async {
                completion(.failure(self.mapError(error)))
            }
            return
        }

        let reason = R.Strings.authorization_biometry_reason.localized()
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, evaluationError in
            DispatchQueue.main.async {
                if success {
                    completion(.success(()))
                } else if let error = evaluationError {
                    completion(.failure(self.mapLAError(error)))
                } else {
                    completion(.failure(BiometryError.authenticationFailed))
                }
            }
        }
    }

    // MARK: - Private
    private func mapError(_ error: NSError?) -> BiometryError {
        guard let error = error else { return .notAvailable }
        return mapLAError(error)
    }

    private func mapLAError(_ error: Error) -> BiometryError {
        let laError = error as NSError

        switch laError.code {
        case LAError.biometryNotAvailable.rawValue:
            return .notAvailable
        case LAError.biometryNotEnrolled.rawValue:
            return .notEnrolled
        case LAError.authenticationFailed.rawValue:
            return .authenticationFailed
        case LAError.userCancel.rawValue:
            return .userCancelled
        case LAError.systemCancel.rawValue:
            return .systemCancel
        case LAError.passcodeNotSet.rawValue:
            return .passcodeNotSet
        case LAError.biometryLockout.rawValue:
            return .biometryLockout
        default:
            return .unknown(error)
        }
    }
}
