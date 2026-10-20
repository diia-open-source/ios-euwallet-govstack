import Foundation
import WalletCore
import WalletDomainModels
import EudiWalletKit
import MdocDataTransfer18013

extension DocElements {
    /// Convert an upstream DocElements (mso-mdoc or sd-jwt) into the app's domain
    /// RequestedDocument. Collapses the msoMdoc/sdJwt distinction — downstream code
    /// reads namespace+field uniformly regardless of credential format.
    func toDomainRequestedDocument() -> RequestedDocument {
        RequestedDocument(
            id: docId,
            docTypeOrVct: docTypeOrVct,
            isValid: isValid,
            selectedItemsDictionary: selectedItemsDictionary.mapValues { items in
                items.map { $0.toDomainRequestedField() }
            }
        )
    }
}

extension RequestItem {
    func toDomainRequestedField() -> RequestedField {
        RequestedField(
            elementIdentifier: elementIdentifier,
            elementPath: elementPath,
            isOptional: isOptional,
            intentToRetain: intentToRetain
        )
    }
}

extension SharingDisclosure {
    /// Convert the app's domain disclosure into the upstream `RequestItems` structure
    /// that `wallet.session.sendResponse(itemsToSend:)` expects. Internal — call sites
    /// in WalletCore use this; downstream never sees the raw `RequestItems` type.
    func toUpstreamRequestItems() -> RequestItems {
        mapValues { byNamespace in
            byNamespace.mapValues { fields in
                fields.map { RequestItem(elementPath: $0.elementPath, intentToRetain: $0.intentToRetain, isOptional: $0.isOptional) }
            }
        }
    }
}
