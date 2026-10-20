import Foundation

/// Credential claim → display label key mapping.
///
/// Wallet credentials expose claims by short element identifier (e.g. `family_name`,
/// `birth_date`, `resident_address`). UI surfaces — primarily the sharing disclosure
/// screen — need to render those with human-readable labels.
///
/// The current raw-value prefix on the matching `WalletStringKey` cases is a legacy
/// convention scheduled for removal as part of the white-label rename pass (see the
/// roadmap's final-step entry); when that lands, only the implementation here will
/// need to change.
///
/// Until the deployment-specific disclosure JSON resource was removed, its per-doc-type
/// groups shipped identical labels for every shared key — confirmed via diff. If a
/// future credential extension introduces doc-type-specific divergence (different
/// labels for the same element identifier across doc types), extend this helper to
/// take a `docType` argument and prefer scoped keys before falling back to the
/// generic mapping.
public extension WalletStringKey {
    /// Resolves a credential element identifier to its display-label case.
    /// Returns nil for unknown identifiers; callers fall back to the credential's
    /// own claim displayName, then the raw identifier.
    static func claimLabel(forElementIdentifier identifier: String) -> WalletStringKey? {
        return WalletStringKey(rawValue: "eudi_label_\(identifier)")
    }
}
