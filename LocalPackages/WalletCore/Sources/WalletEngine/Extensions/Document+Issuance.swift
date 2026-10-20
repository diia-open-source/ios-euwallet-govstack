import Foundation
import WalletCore
import WalletDomainModels
import EudiWalletKit
import WalletStorage

extension WalletStorage.Document {
    /// Convert an upstream wallet-storage document into the app's domain issuance result.
    /// Uses `EudiWalletKit`'s extension property `authorizePresentationUrl` from the
    /// pending-issuance flow.
    func toIssuanceResult() -> IssuanceResult {
        IssuanceResult(
            id: id,
            docType: docType,
            authorizePresentationUrl: authorizePresentationUrl,
            status: IssuanceResult.Status(status)
        )
    }
}

extension IssuanceResult.Status {
    init(_ upstream: DocumentStatus) {
        switch upstream {
        case .issued: self = .issued
        case .deferred: self = .deferred
        case .pending: self = .pending
        }
    }
}
