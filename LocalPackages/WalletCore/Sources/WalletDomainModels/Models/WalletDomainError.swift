//
//  WalletDomainError.swift
//

import Foundation

public enum WalletDomainError: Error {
    case missingMetadata
    case noDocumentsIssued
    /// The issuer's signed metadata could not be trusted — its certificate chain failed validation (invalid) or no matching trusted root was found.
    /// Surfaced so the issuance UI can show a dedicated "Untrusted issuer" alert instead of the generic error.
    case issuerNotTrusted
}
