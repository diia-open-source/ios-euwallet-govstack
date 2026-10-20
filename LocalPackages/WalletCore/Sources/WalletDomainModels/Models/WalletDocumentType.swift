import Foundation

public enum WalletDocumentType: String, Codable, Sendable {
    case pidMdoc = "eu.europa.ec.eudi.pid.1"
    case pidSdJwt = "urn:eudi:pid:1"
    case mdl = "org.iso.18013.5.1.mDL"

    public var isPid: Bool {
        switch self {
        case .pidMdoc, .pidSdJwt: true
        default: false
        }
    }

    public static let allPidTypes: [WalletDocumentType] = [.pidMdoc, .pidSdJwt]
}

public extension WalletDocumentType {
    var displayName: String {
        switch self {
        case .pidMdoc: WalletStringKey.pidMdocDocumentName.localized()
        case .pidSdJwt: WalletStringKey.pidSdjwtDocumentName.localized()
        case .mdl: WalletStringKey.mdlDocumentName.localized()
        }
    }

    var docType: DocType {
        switch self {
        case .pidMdoc, .pidSdJwt: .pidDocument
        case .mdl: .mdlDocument
        }
    }
}
