import Foundation
import WalletCore
import WalletDomainModels
import EudiWalletKit
import OpenID4VCI

extension OfferedIssuanceModel {
    /// Convert an upstream offered issuance model into the app's domain representation.
    /// The `uri` parameter is supplied by the caller because upstream doesn't retain it.
    /// The upstream model itself is cached separately by `WalletKitController` (keyed by `uri`) so the controller can round-trip the offer back into `wallet.issueDocumentsByOfferUrl(...)` without re-resolving — the domain struct does not need to carry the SDK reference.
    func toDomainOffer(uri: String) -> IssuanceOffer {
        IssuanceOffer(
            uri: uri,
            issuerName: issuerName,
            issuerLogoUrl: issuerLogoUrl,
            documents: docModels.map { IssuanceOfferedDocument(displayName: $0.displayName, docTypeOrVct: $0.docTypeOrVct) },
            txCodeSpec: txCodeSpec.map { TxCodeSpec(length: $0.length, isNumeric: $0.inputMode == .numeric) }
        )
    }
}
