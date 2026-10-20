import Foundation

enum R {
    enum Strings: String {
        // MARK: - Accessibility
        case general_accessibility_close
        case general_accessibility_back_button_label
        case main_screen_accessibility_top_qr_scanner_button
        case main_screen_accessibility_bottom_bar_cell_have_updates

        case documents_accessibility_change_order_label
        case documents_accessibility_change_order_hint
        case documents_accessibility_change_order_announce

        // MARK: - General
        case general_cancel
        case general_problem_ok
        case issuance_generic_error_title
        case wallet_provider_unexpected_response
        case wallet_provider_http_error
        case wallet_no_issuers_configured
        
        // MARK: - Splash Screen
        case splash_screen_title

        // MARK: - Authorization
        case authorization_welcome
        case authorization_authorization
        case authorization_forget
        case authorization_triple_error
        case authorization_repeat
        case authorization_repeat_after_attempts
        case authorization_authorize
        case authorization_info
        case authorization_personal_data_message
        case authorization_enter_pin_title
        case authorization_dont_remember_pin
        case authorization_new_pin_details
        case authorization_repeat_pin_details

        // MARK: - Documents accessibility
        case documents_accessibility_no_internet

        // MARK: - DocumentsGeneral
        case document_reordering_title
        case document_reordering_docs_number_small
        case document_reordering_docs_number_big
        case document_reordering_stub_title
        case document_reordering_stub_description
        case document_general_full_information
        case document_general_revoke_document
        
        // MARK: - Menu
        case menu_support
        case menu_title_settings
        case menu_title_transactions
        case menu_title_scan_qr
        case menu_version
        case menu_change_pin
        case menu_logout
        case menu_logout_title
        case menu_logout_message
        case menu_logout_cancel
        case menu_change_pin_success_emoji
        case menu_change_pin_success_title
        case menu_change_pin_success_description
        case menu_change_pin_thank
        
        // MARK: - Settings
        case settings_docs_order
        case settings_biometry_toggle
        
        // MARK: - Main
        case main_screen_feed
        case main_screen_menu
        case main_screen_documents
        
        // MARK: - QRCodeScanner
        case qr_scanner_title
        case qr_scanner_description
        case photo_problem
        case photo_problem_description
        case permissions_camera_not_granted
        case permissions_camera_settings
        case permissions_settings
        case permissions_exit
        case qr_incorrect_code
        
        // MARK: - DocumentsCopyRequest
        case doc_copy_title
        
        // MARK: - User identification
        case user_identification_start_title
        case user_identification_start_details
        
        // MARK: - Errors
        case error_no_internet
        
        // MARK: - Feed
        case feed_ticker_label
        case feed_qr_title
        
        // MARK: - Service
        case services_list_title
        case public_services_search_empty
        case public_services_search_placeholder
        case public_services_search
        case services_unavailable
        
        case document_valid_until_ticker

        // MARK: - Documents
        case pid_document_name
        case pid_mdoc_document_name
        case pid_sdjwt_document_name
        case mdl_document_name
        case document_gender_not_known
        case document_gender_male
        case document_gender_female
        case document_gender_not_applicable
        case documents_qr_hold_to_reader
        case eudi_qr_bluetooth_access_required_title
        case eudi_qr_bluetooth_access_required_description
        case eudi_qr_bluetooth_turn_on_title
        case eudi_qr_bluetooth_turn_on_description
        case eudi_qr_bluetooth_settings_button

        // MARK: - Document Descriptions
        case pid_mdoc_document_description
        case pid_sdjwt_document_description
        case mdl_document_description
        case document_issuer

        // MARK: - Data Sharing Alerts
        case sharing_success_title
        case sharing_success_button
        case sharing_error_title
        case sharing_error_description_default
        case sharing_error_claim_not_found
        case sharing_error_document_not_found
        case sharing_no_documents_title
        case sharing_no_documents_description
        case sharing_no_documents_continue
        case sharing_no_mdoc_title
        case sharing_no_mdoc_description
        case sharing_connection_lost_title
        case sharing_connection_lost_description
        case sharing_selective_data_warning
        case sharing_untrusted_verifier_title
        case sharing_untrusted_verifier_description
        case sharing_untrusted_verifier_button
        case sharing_screen_title
        case sharing_screen_subtitle
        case sharing_screen_data_optional_info
        case sharing_screen_description
        case sharing_screen_button
        case sharing_default_relying_party
        case sharing_default_data_request_info
        case sharing_unknown_document
        case sharing_bluetooth_required_for_proximity

        // MARK: - Document Issuance Screen
        case issuance_screen_title
        case issuance_screen_subtitle
        case issuance_screen_description
        case issuance_screen_button_add
        case issuance_screen_button_cancel
        case issuance_success_title
        case issuance_success_description
        case issuance_success_button
        case issuance_error_title
        case issuance_error_description
        case issuance_error_button
        case issuance_duplicate_document_title
        case issuance_duplicate_document_description
        case issuance_pid_not_found_title
        case issuance_pid_not_found_description
        case issuance_unsupported_document_title
        case issuance_unsupported_document_description
        case issuance_untrusted_issuer_title
        case issuance_untrusted_issuer_description
        case issuance_untrusted_issuer_button
        case deferred_issuance_pending_title
        case deferred_issuance_pending_description
        case deferred_issuance_completed_title
        case deferred_issuance_completed_description
        case deferred_issuance_failed_title
        case deferred_issuance_failed_description
        case deferred_document_issuer_label
        case deferred_document_in_progress_label
        case deferred_document_pending_label
        case deferred_document_time_to_issue_label
        case deferred_document_time_to_issue_value
        case transaction_code_screen_title
        case transaction_code_input_title
        case transaction_code_field_label
        case transaction_code_field_placeholder
        case transaction_code_done

        // MARK: - Add Document Screen
        case add_document_title
        case add_document_description
        case add_document_choose_from_list
        case add_document_scan_qr
        case add_document_empty_title
        case add_document_empty_description
        case add_document_offline_title
        case add_document_offline_description
        case add_document_offline_retry

        // MARK: - Document Revocation
        case document_revoked_title
        case document_revoked_description
        case document_revoked_push_title
        case document_revoked_push_body
        case document_revoked_remove_action
        case document_delete_alert_title
        case document_delete_alert_description
        case document_delete_alert_delete_action
        case document_delete_success_title
        case document_delete_error_title

        // MARK: - Document Expiration
        case document_expired_title
        case document_expired_description
        case document_expired_delete_action
        
        //MARK: - Transaction Log
        case transaction_log_status_incomplete
        case transaction_log_status_failed
        case transaction_log_status_completed
        case transaction_log_stub_title
        case transaction_log_stub_description
        case transaction_log_unidentified_relying_party
        case transaction_log_document_deleted
        case trascation_log_data_shared
        case transaction_log_sharing
        case transaction_log_issuance
        case transaction_log_signing
        case transaction_log_deletion
        case transaction_details_title
        case transaction_details_document_not_found_title
        case transaction_details_document_not_found_description
        case transaction_details_document_not_found_message

        // MARK: - EUDI Document Labels
        case eudi_label_pid
        case eudi_label_national_id
        case eudi_label_birth_date
        case eudi_label_date_of_birth
        case eudi_label_nationality
        case eudi_label_birth_place
        case eudi_label_place_of_birth
        case eudi_label_sex
        case eudi_label_issuance_date
        case eudi_label_expiry_date
        case eudi_label_issuance_authority
        case eudi_label_issuing_country
        case eudi_label_issuing_jurisdiction
        case eudi_label_personal_administrative_number
        case eudi_label_resident_address
        case eudi_label_resident_street
        case eudi_label_resident_house_number
        case eudi_label_resident_city
        case eudi_label_resident_state
        case eudi_label_resident_country
        case eudi_label_resident_postal_code
        case eudi_label_email_address
        case eudi_label_mobile_phone_number
        case eudi_label_category
        case eudi_label_vehicle_category_code
        case eudi_label_age_over_18
        case eudi_label_age_over_format
        case eudi_label_age
        case eudi_label_age_birth_year
        case eudi_label_family_name
        case eudi_label_given_name
        case eudi_label_national_family_name
        case eudi_label_national_given_name
        case eudi_label_administrative_number
        case eudi_label_date_of_issue
        case eudi_label_authority
        case eudi_label_distinguishing_sign
        case eudi_label_height
        case eudi_label_eye_colour
        case eudi_label_hair_colour
        case eudi_label_weight
        case eudi_label_birth_city
        case eudi_label_birth_country
        case eudi_label_birth_state
        case eudi_label_family_name_birth
        case eudi_label_given_name_birth
        case eudi_label_gender
        case eudi_label_issuing_authority
        case eudi_label_portrait
        case eudi_label_signature
        case eudi_label_restrictions
        case eudi_value_male
        case eudi_value_female
        case eudi_value_unknown
        case eudi_value_yes
        case eudi_value_no
        
        func localized() -> String {
            let localized = NSLocalizedString(rawValue, bundle: Bundle.main, comment: "")
            return localized
        }
        
        func localized(with argument: String) -> String {
            let localized = NSLocalizedString(rawValue, bundle: Bundle.main, comment: "")
            return String(format: localized, argument)
        }
        
        func formattedLocalized(arguments: CVarArg...) -> String {
            let localized = NSLocalizedString(rawValue, bundle: Bundle.main, comment: "")
            return String(format: localized, arguments)
        }
    }
}
