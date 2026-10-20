import Foundation
import WalletCore
import WalletDomainModels
import EudiWalletKit
import MdocDataModel18013

public extension TransactionLog {
    /// Convert an upstream EudiWalletKit transaction log into the app's domain representation.
    /// Centralizes the parsing/localization/payload-decoding that used to be scattered across
    /// `TransactionStatusMapper`, `TransactionDetailsViewDataMapper`, and view-state factories.
    func toDomainEntry() -> TransactionLogEntry {
        let createdAt = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let kind = resolveKind()
        let (title, documentTitle) = resolveTitles(for: kind)
        return TransactionLogEntry(
            id: timestamp,
            createdAt: createdAt,
            status: status.toDomain(),
            kind: kind,
            errorMessage: errorMessage,
            title: title,
            documentTitle: documentTitle
        )
    }
}

public extension TransactionLog.Status {
    func toDomain() -> TransactionLogEntry.Status {
        switch self {
        case .completed: return .completed
        case .failed: return .failed
        case .incomplete: return .incomplete
        }
    }
}

private extension TransactionLog {
    func resolveKind() -> TransactionLogEntry.Kind {
        switch type {
        case .presentation:
            let data = PresentationLogData(self, uiCulture: nil)
            let party = relyingParty.map { TransactionParty(name: $0.name) }
            let documentTitles = data.documents.compactMap(\.displayName)
            return .presentation(party: party, documentTitles: documentTitles)

        case .issuance:
            let data = IssuanceLogData(self)
            return .issuance(
                party: TransactionParty(name: data.issuingParty.name),
                documentId: data.documentId
            )

        case .signing:
            let party = relyingParty.map { TransactionParty(name: $0.name) }
            return .signing(party: party)

        case .deletion:
            let data = DeletionLogData(self)
            return .deletion(docType: data.docType)
        }
    }

    func resolveTitles(for kind: TransactionLogEntry.Kind) -> (title: String, documentTitle: String?) {
        switch kind {
        case .presentation(let party, let documentTitles):
            let title = party?.name ?? WalletStringKey.transactionLogUnidentifiedRelyingParty.localized()
            return (title, documentTitles.first ?? displayName)

        case .issuance(let party, _):
            return (party.name, displayName)

        case .signing(let party):
            let title = displayName
                ?? party?.name
                ?? WalletStringKey.transactionLogUnidentifiedRelyingParty.localized()
            return (title, displayName)

        case .deletion(let docType):
            let title = WalletStringKey.transactionLogDocumentDeleted.localized()
            let data = DeletionLogData(self)
            let documentTitle = data.displayName ?? docType
            return (title, documentTitle)
        }
    }
}
