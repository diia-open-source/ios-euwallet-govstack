import Foundation

/// Credential data-format taxonomy. Mirrors `WalletStorage.DocDataFormat` upstream
/// without exposing it.
public enum CredentialFormat: String, Sendable, Hashable, CaseIterable {
    case msoMdoc = "mso_mdoc"
    case sdJwtVc = "vc+sd-jwt"
    case unknown
}
