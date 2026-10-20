
import Foundation
import DiiaUIComponents
import DiiaCommonTypes

public struct DSFullDocumentModel: StatusedExpirableProtocol {

    public var status: DocumentStatusCode
    public var expirationDate: Date
    public let data: [DSDocumentData]

    public init(status: DocumentStatusCode,
                expirationDate: Date,
                data: [DSDocumentData]) {
        self.status = status
        self.expirationDate = expirationDate
        self.data = data
    }
}

public struct DSDocumentData: Codable, Hashable {
    public let docStatus: Int
    public let id: String
    public let docNumber: String
    public let content: [DSDocumentContent]?
    public let docData: DSDocData
    public let frontCard: DSDocumentModel?
    public let fullInfo: [AnyCodable]?

    public init(docStatus: Int,
                id: String,
                docNumber: String,
                content: [DSDocumentContent]? = nil,
                docData: DSDocData,
                frontCard: DSDocumentModel? = nil,
                fullInfo: [AnyCodable]? = nil) {
        self.docStatus = docStatus
        self.id = id
        self.docNumber = docNumber
        self.content = content
        self.docData = docData
        self.frontCard = frontCard
        self.fullInfo = fullInfo
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(docNumber)
        hasher.combine(docStatus)
    }

    public static func == (lhs: DSDocumentData, rhs: DSDocumentData) -> Bool {
        return lhs.docNumber == rhs.docNumber &&
        lhs.id == rhs.id &&
        lhs.docStatus == rhs.docStatus &&
        lhs.docData == rhs.docData &&
        lhs.frontCard == rhs.frontCard
    }
}

public struct DSDocData: Codable, Equatable {
    public let docName: String
    public let docType: String?
    public let fullName: String?

    public init(docName: String,
                docType: String? = nil,
                fullName: String? = nil) {
        self.docName = docName
        self.docType = docType
        self.fullName = fullName
    }
}

public struct DSDocumentContent: Codable {
    public let image: String
    public let code: DSDocumentContentData

    public init(image: String,
                code: DSDocumentContentData) {
        self.image = image
        self.code = code
    }
}

public struct DSDocumentModel: Codable, Equatable {
    public let docHeadingOrg: DSDocumentHeading?
    public let tableBlockTwoColumnsPlaneOrg: DSTableBlockTwoColumnPlaneOrg?
    public let tableBlockPlaneOrg: DSTableBlockItemModel?
    public let subtitleLabelMlc: DSTitleLabelMlc?
    public let tickerAtm: DSTickerAtom?
    public let docButtonHeadingOrg: DSDocumentHeading?

    public init(docHeadingOrg: DSDocumentHeading? = nil,
                tableBlockTwoColumnsPlaneOrg: DSTableBlockTwoColumnPlaneOrg? = nil,
                tableBlockPlaneOrg: DSTableBlockItemModel? = nil,
                subtitleLabelMlc: DSTitleLabelMlc? = nil,
                tickerAtm: DSTickerAtom? = nil,
                docButtonHeadingOrg: DSDocumentHeading? = nil) {
        self.docHeadingOrg = docHeadingOrg
        self.tableBlockTwoColumnsPlaneOrg = tableBlockTwoColumnsPlaneOrg
        self.tableBlockPlaneOrg = tableBlockPlaneOrg
        self.subtitleLabelMlc = subtitleLabelMlc
        self.tickerAtm = tickerAtm
        self.docButtonHeadingOrg = docButtonHeadingOrg
    }
}
