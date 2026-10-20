import Foundation

/// App-domain representation of a credential the wallet holds.
///
/// Unifies the two upstream concepts:
/// - `MdocDataModel18013.DocClaimsDecodable` (issued credential with decoded claims)
/// - `WalletStorage.Document` in deferred / pending state (claims not yet issued)
///
/// The `status` field disambiguates. `claims` is empty for deferred / pending entries
/// because upstream doesn't have decoded claims for them yet.
public struct Credential: Sendable, Hashable, Identifiable {
    public let id: String
    public let docType: String
    public let displayName: String?
    public let issuerDisplayName: String?
    public let credentialIssuerIdentifier: String?
    public let format: CredentialFormat
    public let claims: [DocumentClaim]
    public let status: Status
    public let createdAt: Date

    /// Cryptographic validity window from the credential envelope —
    /// mDOC MSO `validityInfo.{validFrom,validUntil}` or SD-JWT `iat`/`exp`.
    /// Full datetime precision (seconds). Prefer over the human-readable
    /// `expiry_date` / `date_of_expiry` claim strings for expiry decisions.
    /// Nil for deferred/pending entries (no decoded envelope yet).
    public let validFrom: Date?
    public let validUntil: Date?

    /// Issuer-published token-status-list reference, if the credential envelope
    /// carries one (mDOC `IssuerAuth.statusIdentifier` or SD-JWT `status.status_list`).
    /// `statusListURI` is the JWT-protected status-list endpoint; `statusListIdx`
    /// is this credential's bit offset within that list. Both are nil for
    /// deferred/pending entries (no decoded envelope yet) and for credentials
    /// whose issuer did not emit a status list.
    public let statusListURI: String?
    public let statusListIdx: Int?

    public init(
        id: String,
        docType: String,
        displayName: String?,
        issuerDisplayName: String?,
        credentialIssuerIdentifier: String?,
        format: CredentialFormat,
        claims: [DocumentClaim],
        status: Status,
        createdAt: Date,
        validFrom: Date? = nil,
        validUntil: Date? = nil,
        statusListURI: String? = nil,
        statusListIdx: Int? = nil
    ) {
        self.id = id
        self.docType = docType
        self.displayName = displayName
        self.issuerDisplayName = issuerDisplayName
        self.credentialIssuerIdentifier = credentialIssuerIdentifier
        self.format = format
        self.claims = claims
        self.status = status
        self.createdAt = createdAt
        self.validFrom = validFrom
        self.validUntil = validUntil
        self.statusListURI = statusListURI
        self.statusListIdx = statusListIdx
    }

    public enum Status: String, Sendable, Hashable, CaseIterable {
        case issued
        case deferred
        case pending
    }

    public var isDeferred: Bool { status == .deferred }
    public var isPending: Bool { status == .pending }
}

public extension Credential {
    /// Whether the credential's cryptographic validity window has elapsed at `now`.
    ///
    /// Reads the envelope `validUntil` (mDOC MSO `validityInfo.validUntil` or SD-JWT `exp`).
    /// A `nil` `validUntil` — deferred/pending entries, or restored pre-migration models that only carry the legacy date-only claim string — is treated as **not** expired, so callers fail open rather than wrongly blocking a document whose envelope expiry is unknown.
    ///
    /// This is the envelope-level check used by sharing gates; the gallery's `DocumentExpiryResolver` additionally resolves the legacy claim-string fallback for display.
    func isExpired(asOf now: Date = Date()) -> Bool {
        guard let validUntil else { return false }
        return validUntil < now
    }
}
