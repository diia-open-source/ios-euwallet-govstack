import Foundation
import WalletAppStorage

public struct PinCodeStorage: PinCodeStorageProtocol {
    let storage: StoreHelper

    public init(storage: StoreHelper) {
        self.storage = storage
    }

    public func getIncorrectPincodeAttemptsCount() -> Int? {
        return storage.getValue(forKey: .incorrectPincodeCount)
    }

    public func saveIncorrectPincodeAttemptsCount(_ value: Int) {
        storage.save(value, type: Int.self, forKey: .incorrectPincodeCount)
    }
}
