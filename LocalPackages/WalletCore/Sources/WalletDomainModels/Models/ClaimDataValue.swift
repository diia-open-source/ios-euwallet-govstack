import Foundation

/// The decoded value of a single document claim. Replaces direct use of
/// `MdocDataModel18013.DocDataValue` in downstream / WalletCore-internal code.
public struct ClaimDataValue: Sendable, Hashable, CustomStringConvertible, CustomDebugStringConvertible {
    public var description: String { stringValue }
    public var debugDescription: String {
        if let b = booleanValue { return "boolean(\(b))" }
        if let i = integerValue { return "integer(\(i))" }
        if let d = doubleValue { return "double(\(d))" }
        if let d = dateValue { return "date(\(d))" }
        if let img = imageData { return "bytes(\(img.count) bytes)" }
        return "string(\"\(stringValue)\")"
    }

    public let stringValue: String
    public let booleanValue: Bool?
    public let integerValue: UInt64?
    public let doubleValue: Double?
    public let dateValue: Date?
    public let imageData: Data?

    public init(
        stringValue: String,
        booleanValue: Bool? = nil,
        integerValue: UInt64? = nil,
        doubleValue: Double? = nil,
        dateValue: Date? = nil,
        imageData: Data? = nil
    ) {
        self.stringValue = stringValue
        self.booleanValue = booleanValue
        self.integerValue = integerValue
        self.doubleValue = doubleValue
        self.dateValue = dateValue
        self.imageData = imageData
    }

    /// Generic typed accessor — used by PID/MDL model builders that consume claim
    /// values into `Field<T>` of various T (String, UInt64, Int, Bool, Date, Data...).
    /// Mirrors the shape of upstream `DocDataValue.getValue<T>()` without exposing
    /// the upstream type.
    public func getValue<T>() -> T? {
        if T.self == String.self { return stringValue as? T }
        if T.self == Bool.self { return booleanValue as? T }
        if T.self == UInt64.self { return integerValue as? T }
        if let intValue = integerValue {
            if T.self == Int.self { return Int(intValue) as? T }
            if T.self == Int64.self { return Int64(intValue) as? T }
        }
        if T.self == Double.self { return doubleValue as? T }
        if T.self == Date.self { return dateValue as? T }
        if T.self == Data.self { return imageData as? T }
        return nil
    }
}
