
import Foundation

internal extension R {
    enum Strings: String, CaseIterable {

        // MARK: - Accessibility
        case auth_accessibility_pincode_clear_button_label
        case general_accessibility_back_button_label
        case general_accessibility_back_button_hint
        case auth_accessibility_pincode_header_hint
        case general_accessibility_back_button_step
        case auth_accessibility_biometry_request_approve
        case auth_accessibility_biometry_request_later
        case general_accessibility_incorrect_password
        
        // MARK: - General
        case general_step
        case general_cancel
        case general_cancel_hint

        // MARK: - Authorization
        case authorization_create_pincode
        case authorization_repeat_pincode
        case authorization_allow
        case authorization_allow_later
        case authorization_new_pin_details
        case authorization_repeat_pin_details
        case authorization_template_cancel_title
        case authorization_template_cancel_description
        case authorization_template_cancel_button_primary
        case authorization_template_cancel_button_secondary


        // MARK: - Biometry
        case authorization_biometry_fallback_title
        case authorization_biometry_reason
        case biometry_setup_title
        case biometry_setup_description
        case biometry_setup_allow
        case biometry_setup_maybe_later
        case biometry_accessibility_button_hint
        case general_ok

        // MARK: - Menu
        case menu_change_pin_current
        case menu_change_pin_new
        case menu_change_pin_olddescr
        case menu_change_pin_repeat
        
        func localized() -> String {
            let localized = NSLocalizedString(rawValue, bundle: Bundle.module, comment: "")
            return localized
        }
        
        func localized(with argument: String) -> String {
            let localized = NSLocalizedString(rawValue, bundle: Bundle.module, comment: "")
            return String(format: localized, argument)
        }

        func formattedLocalized(arguments: CVarArg...) -> String {
            let localized = NSLocalizedString(rawValue, bundle: Bundle.module, comment: "")
            return String(format: localized, arguments)
        }
    }
}
