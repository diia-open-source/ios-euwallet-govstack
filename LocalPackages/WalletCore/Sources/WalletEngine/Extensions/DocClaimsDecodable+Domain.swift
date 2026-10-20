import Foundation
import WalletCore
import WalletDomainModels
import MdocDataModel18013
import WalletStorage

public extension DocClaimsDecodable {
    /// Convert an upstream issued credential into the app's domain representation.
    func toDomainCredential() -> Credential {
        Credential(
            id: id,
            docType: docType,
            displayName: displayName,
            issuerDisplayName: issuerDisplay?.first?.name,
            credentialIssuerIdentifier: credentialIssuerIdentifier,
            format: CredentialFormat(docDataFormat),
            claims: docClaims.map { $0.toDomainClaim() },
            status: .issued,
            createdAt: createdAt,
            // Pulled from MSO `validityInfo` (mDOC) or `iat`/`exp` (SD-JWT) by the
            // SDK — full datetime precision, unlike the date-only claim strings.
            validFrom: validFrom,
            validUntil: validUntil,
            // Issuer-signed token-status-list reference (mDOC `IssuerAuth.statusIdentifier`
            // or SD-JWT `status.status_list`). Nil when the issuer didn't emit one.
            statusListURI: statusIdentifier?.uriString,
            statusListIdx: statusIdentifier?.idx
        )
    }
}

public extension WalletStorage.Document {
    /// Convert a deferred / pending wallet-storage document into a domain Credential.
    /// The `claims` array is empty because upstream hasn't decoded any yet — call sites
    /// can rely on `.status` to know they shouldn't try to render claim content.
    func toDomainCredential() -> Credential {
        let metadata = DocMetadata(from: self.metadata)
        let domainStatus: Credential.Status = switch status {
        case .deferred: .deferred
        case .pending: .pending
        case .issued: .issued
        }
        let resolvedDisplayName = metadata?.getDisplayName(Locale.current.language.languageCode?.identifier).flatMap { $0.isEmpty ? nil : $0 }
            ?? metadata?.display?.first?.name
            ?? displayName
        return Credential(
            id: id,
            docType: docType,
            displayName: resolvedDisplayName,
            issuerDisplayName: metadata?.issuerDisplay?.first?.name,
            credentialIssuerIdentifier: metadata?.credentialIssuerIdentifier,
            format: CredentialFormat(docDataFormat),
            claims: [],
            status: domainStatus,
            createdAt: createdAt
        )
    }
}

extension DocClaim {
    func toDomainClaim() -> DocumentClaim {
        DocumentClaim(
            id: id,
            namespace: namespace,
            name: name,
            displayName: displayName,
            path: path,
            dataValue: dataValue.toDomainValue(stringValue: stringValue),
            isOptional: isOptional,
            order: order,
            children: children?.map { $0.toDomainClaim() }
        )
    }
}

extension DocDataValue {
    func toDomainValue(stringValue: String) -> ClaimDataValue {
        switch self {
        case .boolean(let b):
            return ClaimDataValue(stringValue: stringValue, booleanValue: b)
        case .integer(let i):
            return ClaimDataValue(stringValue: stringValue, integerValue: i)
        case .double(let d):
            return ClaimDataValue(stringValue: stringValue, doubleValue: d)
        case .string:
            return ClaimDataValue(stringValue: stringValue)
        case .date:
            return ClaimDataValue(stringValue: stringValue, dateValue: dateValue)
        case .bytes(let b):
            return ClaimDataValue(stringValue: stringValue, imageData: Data(b))
        case .array, .dictionary:
            return ClaimDataValue(stringValue: stringValue)
        @unknown default:
            return ClaimDataValue(stringValue: stringValue)
        }
    }
}

extension CredentialFormat {
    init(_ upstream: DocDataFormat) {
        switch upstream {
        case .cbor: self = .msoMdoc
        case .sdjwt: self = .sdJwtVc
        @unknown default: self = .unknown
        }
    }
}
