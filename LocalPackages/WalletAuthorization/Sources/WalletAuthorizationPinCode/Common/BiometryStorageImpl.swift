import Foundation
import WalletAppStorage

public struct BiometryStorage: BiometryStorageProtocol {
    private let storage: StoreHelper

    public init(storage: StoreHelper = .instance) {
        self.storage = storage
    }

    public var isBiometryEnabled: Bool {
        return storage.getValue(forKey: .biometryEnabled) ?? false
    }

    public func setBiometryEnabled(_ enabled: Bool) {
        storage.save(enabled, type: Bool.self, forKey: .biometryEnabled)
    }
}
