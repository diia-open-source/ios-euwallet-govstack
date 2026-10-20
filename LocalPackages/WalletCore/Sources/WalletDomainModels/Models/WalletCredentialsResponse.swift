//
//  WalletCredentialsResponse.swift
//

import Foundation
import DiiaCommonTypes

/// Thrown by issuance flows when the issuer returns an alert-template payload instead of a credential — the caller (`WalletOnboardingPresenter`) catches `.template` and surfaces the alert as-is.
public enum WalletCredentialIssuanceError: Error {
    case template(AlertTemplate)
}
