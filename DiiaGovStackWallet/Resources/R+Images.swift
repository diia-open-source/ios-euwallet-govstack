import UIKit

extension R {
    enum image: String {
        // MARK: - Buttons
        case clear
        case menu_back
        case qrScanner
        case search_light
        
        // MARK: - Images
        case loadingBar
        case ukrainianGradient
        case light_background
        
        // MARK: - IconsMenu
        case menuChangePincode
        case menuSupport
        case menuFeedActive
        case menuFeedInactive
        case menuDocumentsInactive
        case menuDocumentsActive
        case menuServicesInactive
        case menuServicesActive
        case menuSettingsInactive
        case menuSettingsActive
        case settings
        case orderIcon
        
        // MARK: - Icons
        case diia
        case logos
        case tryzub
        case lightCloseIcon
        case documentInfo
        case deleteDocument
        
        // MARK: - Frame
        case leftBottom
        case leftTop
        case rightBottom
        case rightTop
        
        // MARK: - DesignSystem icons
        case ds_certificates = "DS_certificates"
        case ds_drag = "DS_drag"
        case ds_placeholder = "DS_placeholder"
        case ds_stack = "DS_stack"
        case ds_ellipseArrowRight = "DS_ellipseArrowRight"
        case ds_copy = "DS_copy"
        case ds_ellipseKebab = "DS_ellipseKebab"
        case ellipseQrScan

        var image: UIImage? {
            return UIImage(named: rawValue)
        }
        
        var name: String {
            return rawValue
        }
    }
}
