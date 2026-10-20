
import UIKit
import DiiaUIComponents
import WalletDocumentsCommonTypes
import DiiaCommonTypes

public final class DocumentDetailsCommonViewModel {

    // MARK: - Properties
    public var model: DSDocumentData?
    public var images = [DSDocumentContentData: UIImage]()
    public var eventHandler: DSConstructorEventHandler?

    // MARK: - Init
    public init(model: DSDocumentData?,
                images: [DSDocumentContentData: UIImage],
                eventHandler: DSConstructorEventHandler?) {
        self.model = model
        self.images = images
        self.eventHandler = eventHandler
    }

    // MARK: - Public
    func bodyModel() -> [AnyCodable] {
        return model?.fullInfo ?? []
    }
}
