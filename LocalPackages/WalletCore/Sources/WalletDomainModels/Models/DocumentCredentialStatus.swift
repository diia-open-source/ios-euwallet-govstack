//
//  DocumentCredentialStatus.swift
//

import Foundation

/// Represents the status of a document credential.
public enum DocumentCredentialStatus: Sendable {
    case valid
    case revoked
    case suspended
    case unknown
}
