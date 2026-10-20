import Foundation
import WalletAppStorage

public struct AuthorizationStorage: AuthorizationStorageProtocol {
    let storage: StoreHelper

    public init(storage: StoreHelper) {
        self.storage = storage
    }

    public func getHashedPincode() -> String? {
        return storage.getValue(forKey: .authPincode)
    }

    public func saveHashedPincode(_ value: String?) {
        storage.save(value, type: String?.self, forKey: .authPincode)
    }

    public func getAuthToken() -> String? {
        return nil
    }

    public func saveAuthToken(_ value: String?) { }

    public func getLogoutToken() -> String? {
        nil
    }

    public func saveLogoutToken(_ value: String) { }

    public func removeLogoutToken() { }

    public func getLastPincodeDate() -> Date? {
        return storage.getValue(forKey: .lastPincodeDate)
    }

    public func saveLastPincodeDate(_ value: Date) {
        storage.save(value, type: Date.self, forKey: .lastPincodeDate)
    }

    public func removeLastPincodeDate() {
        storage.removeValue(forKey: .lastPincodeDate)
    }
}

// MARK: - Service authorization storage
// The wallet doesn't support Service authorization; these stubs satisfy the protocol surface but never carry real data.
// If a service-auth flow lands later, wire real persistence here.
public extension AuthorizationStorage {
    func getServiceToken() -> String? { nil }
    func saveServiceToken(_ value: String?) { }
    func getServiceLogoutToken() -> String? { nil }
    func saveServiceLogoutToken(_ value: String) { }
    func removeServiceLogoutToken() { }
}
