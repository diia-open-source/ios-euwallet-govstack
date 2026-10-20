//
//  DocumentExpiryResolver.swift
//
//  Single place that answers "when does this document expire" and "is it
//  expired right now". Two callers:
//   • view-state factories — for the `DSFullDocumentModel.expirationDate` field
//   • card view models — to derive the live `isExpired` flag per render
//

import Foundation
import WalletCore
import WalletDomainModels

public enum DocumentExpiryResolver {

    /// Resolve the cryptographic expiry moment for a document.
    ///
    /// - Parameters:
    ///   - primary: The envelope-level value the SDK extracts from MSO
    ///     `validityInfo.validUntil` (mDOC) or `exp` (SD-JWT). Full datetime,
    ///     second-precision. This is the source of truth when available.
    ///   - fallbackString: The legacy date-only issuer claim string
    ///     (`yyyy-MM-dd` — e.g. `expiry_date` / `date_of_expiry`). Used only
    ///     for restored / pre-migration models where `primary` is nil.
    /// - Returns: A concrete `Date`. `.distantFuture` if neither source is
    ///   available, so the caller's comparison treats the doc as not-expired.
    public static func resolveExpiry(primary: Date?, fallbackString: String?) -> Date {
        if let primary {
            return primary
        }
        guard let fallbackString else { return .distantFuture }
        return AppDateFormatter.date(from: fallbackString, source: .yyyyMMdd) ?? .distantFuture
    }

    /// Is the document past expiry at `now`?
    public static func isExpired(validUntil: Date, now: Date = Date()) -> Bool {
        validUntil < now
    }
}
