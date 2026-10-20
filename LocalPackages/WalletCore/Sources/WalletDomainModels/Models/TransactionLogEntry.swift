import Foundation

/// App-domain representation of a transaction log entry.
///
/// Replaces direct use of `MdocDataModel18013.TransactionLog` in downstream code.
/// Localized display strings and the parsed creation date are computed once at construction
/// time (inside `TransactionLog.toDomainEntry()`) so call sites can read them as plain `String`/`Date`
/// without re-parsing upstream payloads or re-running localization on every UI tick.
public struct TransactionLogEntry: Sendable, Hashable, Identifiable {
    public let id: Int64
    public let createdAt: Date
    public let status: Status
    public let kind: Kind
    public let errorMessage: String?

    /// Display title, already localized at construction.
    public let title: String

    /// Optional document subtitle for UI rendering.
    public let documentTitle: String?

    public init(
        id: Int64,
        createdAt: Date,
        status: Status,
        kind: Kind,
        errorMessage: String?,
        title: String,
        documentTitle: String?
    ) {
        self.id = id
        self.createdAt = createdAt
        self.status = status
        self.kind = kind
        self.errorMessage = errorMessage
        self.title = title
        self.documentTitle = documentTitle
    }

    public enum Status: Sendable, Hashable {
        case completed
        case failed
        case incomplete

        public var displayText: String {
            switch self {
            case .completed: return WalletStringKey.transactionLogStatusCompleted.localized()
            case .failed: return WalletStringKey.transactionLogStatusFailed.localized()
            case .incomplete: return WalletStringKey.transactionLogStatusIncomplete.localized()
            }
        }
    }

    public enum Kind: Sendable, Hashable {
        case presentation(party: TransactionParty?, documentTitles: [String])
        case issuance(party: TransactionParty, documentId: String?)
        case signing(party: TransactionParty?)
        case deletion(docType: String?)

        public var displayLabel: String {
            switch self {
            case .presentation: return WalletStringKey.transactionLogSharing.localized()
            case .issuance: return WalletStringKey.transactionLogIssuance.localized()
            case .signing: return WalletStringKey.transactionLogSigning.localized()
            case .deletion: return WalletStringKey.transactionLogDeletion.localized()
            }
        }
    }
}
