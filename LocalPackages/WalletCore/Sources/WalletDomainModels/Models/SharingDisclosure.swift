import Foundation

/// What the wallet sends back to a verifier as the user's selective-disclosure response.
/// Outer key: docId-or-docType (mirrors upstream's free-form key in `RequestItems`).
/// Inner key: namespace.
/// Replaces direct use of `MdocDataTransfer18013.RequestItems` in downstream code.
public typealias SharingDisclosure = [String: [String: [RequestedField]]]
