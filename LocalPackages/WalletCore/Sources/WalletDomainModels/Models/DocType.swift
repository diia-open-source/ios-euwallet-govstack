import UIKit
import WalletDocumentsCommonTypes

public enum DocType: String, Codable, CaseIterable {
    case pidDocument = "PID"
    case mdlDocument = "mDL"

    public var name: String {
        switch self {
        case .pidDocument: WalletStringKey.pidDocumentName.localized()
        case .mdlDocument: WalletStringKey.mdlDocumentName.localized()
        }
    }

    public var stackName: String {
        return name
    }

    public static var allCardTypes: [DocType] {
        return DocType.allCases
    }

    public var faqCategoryId: String {
        switch self {
        case .pidDocument: "pid"
        case .mdlDocument: "mdl"
        }
    }
}

extension DocType: DocumentAttributesProtocol {
    public var docCode: DocTypeCode { return self.rawValue }

    public func warningModel() -> WarningModel? {
        return nil
    }

    public var stackIconAppearance: DocumentStackIconAppearance {
        return .black
    }

    public var isStaticDoc: Bool {
        return false
    }

    public func isDocCodeSameAs(otherDocCode: DocTypeCode) -> Bool {
        DocType(rawValue: docCode) == DocType(rawValue: otherDocCode)
    }
}
