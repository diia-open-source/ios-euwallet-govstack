
import Foundation

public protocol PinCodeStorageProtocol {
    func getIncorrectPincodeAttemptsCount() -> Int?
    func saveIncorrectPincodeAttemptsCount(_ value: Int)
}
