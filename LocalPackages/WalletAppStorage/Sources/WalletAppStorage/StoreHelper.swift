import Foundation
import DiiaCommonTypes
import WalletDomainModels

struct StoreContainer<T>: Codable where T: Codable {
    let value: T
}

public enum StoringKey: String, CaseIterable {
    case hasAppBeenLaunchedBefore = "kUDHasAppBeenLaunchedBefore"
    case lastPincodeDate = "kUDLastPincodeDate"
    case incorrectPincodeCount = "kUDIncorrectPincodeCount"
    case incorrectPincodeChangeCount = "kUDIncorrectPincodeChangeCount"
    case authPincode = "kKCAuthorizationPincode"
    case biometryEnabled = "kUDBiometryEnabled"
    case docsOrder = "kUDDocsOrder"
    case docsStackOrder = "kUDDocsStackOrder"
    case docsFlatOrder = "kUDDocsFlatOrder"

    case pidDocument = "kDSPIDDocument"
    case mdlDocument = "kDSmDLDocument"
}

public protocol StoreHelperProtocol {
    func save<T>(_ value: T, type: T.Type, forKey key: StoringKey) where T: Codable
    func getValue<T>(forKey key: StoringKey) -> T? where T: Codable
    func removeValue(forKey key: StoringKey)
    func clearAllData()
}

public final class StoreHelper: StoreHelperProtocol {
    public static let instance = StoreHelper()

    private init() {}

    private enum StorageType {
        case userDefaults
        case keychain
        
        init(storingKey: StoringKey) {
            switch storingKey {
            case .authPincode, .incorrectPincodeCount:
                self = .keychain
            default:
                self = .userDefaults
            }
        }
    }
    
    // MARK: - Properties
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let userDefaults = UserDefaults.standard
    private let fileManager = FileManager.default
    
    public func save<T>(_ value: T, type: T.Type, forKey key: StoringKey) where T: Codable {
        do {
            let container: StoreContainer<T> = StoreContainer(value: value)
            let data = try encoder.encode(container)
            switch StorageType(storingKey: key) {
            case .keychain:
                saveKeychain(data, forKey: key.rawValue)
            case .userDefaults:
                saveUserDefaults(data: data, key: key.rawValue)
            }
        } catch {
            return
        }
    }
    
    public func getValue<T>(forKey key: StoringKey) -> T? where T: Codable {
        let data: Data?
        switch StorageType(storingKey: key) {
        case .keychain:
            data = getKeychain(withKey: key.rawValue)
        case .userDefaults:
            data = getUserDefaultsValue(withKey: key.rawValue)
        }
        guard let result = data else { return nil }
        
        let decodedContainer = try? decoder.decode(FailableDecodable<StoreContainer<T>>.self, from: result)
        
        return decodedContainer?.value?.value
    }
    
    public func removeValue(forKey key: StoringKey) {
        switch StorageType(storingKey: key) {
        case .keychain:
            saveKeychain(nil, forKey: key.rawValue)
        case .userDefaults:
            userDefaults.set(nil, forKey: key.rawValue)
            userDefaults.synchronize()
        }
    }
    
    public func clearAllData() {
        // Preserve `hasAppBeenLaunchedBefore`: it is an install-lifecycle marker, not per-user data.
        // Clearing it (logout, PIN-attempt exhaustion) makes the next cold launch look like a fresh install and re-run the first-install wipe, deleting the PIN and documents a re-logged-in user has since created.
        StoringKey.allCases
            .filter { $0 != .hasAppBeenLaunchedBefore }
            .forEach { removeValue(forKey: $0) }
        clearCache()
    }
}

// MARK: - Helping Device Storage Methods

private extension StoreHelper {
    enum Constants {
        static let documentsDirectory = "dsDocuments"
    }
    
    // Helping methods for File Manager
    func filesDirectoryUrl() -> URL {
        var fileDirectoryUrl = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        fileDirectoryUrl = fileDirectoryUrl.appendingPathComponent(Constants.documentsDirectory)
        return fileDirectoryUrl
    }
    
    func createDirectoryIfNeeded() throws {
        var fileDirectoryUrl = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        fileDirectoryUrl = fileDirectoryUrl.appendingPathComponent(Constants.documentsDirectory)
        guard !fileManager.fileExists(atPath: fileDirectoryUrl.path) else {
            return
        }
        try fileManager.createDirectory(at: fileDirectoryUrl,
                                        withIntermediateDirectories: true,
                                        attributes: [.protectionKey: FileProtectionType.complete])
    }
    
    func clearCache() {
        guard let cacheURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else { return }
        do {
            let directoryContents = try FileManager.default.contentsOfDirectory( at: cacheURL, includingPropertiesForKeys: nil, options: [])
            for file in directoryContents {
                do {
                    try fileManager.removeItem(at: file)
                } catch {
                }
            }
        } catch {
        }
    }
}

// MARK: - Helping UserDefaults Methods
private extension StoreHelper {
    func saveUserDefaults(data: Data, key: String) {
        userDefaults.set(data, forKey: key)
        userDefaults.synchronize()
    }
    
    func getUserDefaultsValue(withKey key: String) -> Data? {
        return userDefaults.object(forKey: key) as? Data
    }
}

// MARK: - Helping Keychain Methods
private extension StoreHelper {
    /// PIN hash + attempt counter are keychain-backed; restrict them to "unlocked, this device only" so they are unreadable while the device is locked and never migrate to another device or a backup.
    static let keychainAccessibility: CFString = kSecAttrAccessibleWhenUnlockedThisDeviceOnly

    func saveKeychain(_ data: Data?, forKey key: String) {
        DispatchQueue.global().sync(flags: .barrier) {
            let query = keychainQuery(withKey: key)

            if SecItemCopyMatching(query, nil) == noErr {
                if let data = data {
                    SecItemUpdate(query, NSDictionary(dictionary: [
                        kSecValueData: data,
                        kSecAttrAccessible: StoreHelper.keychainAccessibility
                    ]))
                } else {
                    SecItemDelete(query)
                }
            } else {
                if let data = data {
                    query.setValue(data, forKey: kSecValueData as String)
                    query.setValue(StoreHelper.keychainAccessibility, forKey: kSecAttrAccessible as String)
                    SecItemAdd(query, nil)
                }
            }
        }
    }
    
    func getKeychain(withKey key: String) -> Data? {
        let query = keychainQuery(withKey: key)
        query.setValue(kCFBooleanTrue, forKey: kSecReturnData as String)
        query.setValue(kCFBooleanTrue, forKey: kSecReturnAttributes as String)
        
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query, &result)
        
        guard
            let resultsDict = result as? NSDictionary,
            let resultsData = resultsDict.value(forKey: kSecValueData as String) as? Data,
            status == noErr
        else {
            return nil
        }
        return resultsData
    }
    
    func keychainQuery(withKey key: String) -> NSMutableDictionary {
        let result = NSMutableDictionary()
        result.setValue(kSecClassGenericPassword, forKey: kSecClass as String)
        result.setValue(key, forKey: kSecAttrService as String)
        // Accessibility is asserted at write time (see `saveKeychain`), not as a search attribute — including it here would hide items stored under a different accessibility value.
        return result
    }
}
