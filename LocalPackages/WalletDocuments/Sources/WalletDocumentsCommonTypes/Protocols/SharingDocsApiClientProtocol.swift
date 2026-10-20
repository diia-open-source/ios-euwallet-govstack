
import Foundation
import ReactiveKit

// reason for location: is used by DriverLicenseDocument package and Diia itself
public protocol SharingDocsApiClientProtocol {
    // MARK: - Share
    func shareDocument(docType: String, documentId: String, localization: String?) -> Signal<ShareVerificationCodesModel, Error>
    func shareDriverLicense(documentId: String, localization: String?) -> Signal<ShareLinkModel, Error>
}
