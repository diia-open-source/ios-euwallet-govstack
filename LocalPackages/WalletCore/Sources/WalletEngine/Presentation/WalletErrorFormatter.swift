//
//  WalletErrorFormatter.swift
//

import Foundation
import WalletCore
import WalletDomainModels
// `EudiWalletKit` is needed for the `Document.getDisplayName(_:)` / `Document.getClaimDisplayNames(_:)` extensions used by `preloadMetadata()`.
// Importing it here is allowed — WalletCore is the only module permitted to depend on the SDK.
// Callers receive `PresentationError` instead of the upstream `WalletError`, so the boundary holds for downstream code.
import EudiWalletKit
import WalletStorage

/// Transforms SDK errors into user-friendly localized messages.
///
/// Primary path: structured `code` + `context` on the domain error.
/// The SDK populates `claimPath` in context for `.claimNotFound` / `.claimValueMismatch` / `.claimSetNotSatisfied`, and `docType` for `.credentialNotFound`.
///
/// Fallback path: legacy string parsing of the error description, kept for safety in case an error reaches us without a populated `code`.
///
/// Conforms to `WalletErrorFormatting` so features reach this instance through `WalletDependencies.walletErrorFormatter` rather than the concrete type — the host bootstraps a single instance at app launch.
/// `@unchecked Sendable` because the two metadata dictionaries are mutated only via `MainActor.run` inside `preloadMetadata()`; reads happen wherever, which can race during a preload but is accepted (worst case: a single formatted error reflects pre-preload state and gets replaced on the next reload).
public final class WalletErrorFormatter: WalletErrorFormatting, @unchecked Sendable {

    /// Pre-loaded claim display names from issuer metadata.
    /// Key: claimKey, Value: displayName.
    /// Populated by `preloadMetadata()` before errors are shown.
    private var claimDisplayNames: [String: String] = [:]
    private var documentDisplayNames: [String: String] = [:]

    public init() {}

    /// Pre-loads claim and document display names from the issuer's credential metadata.
    /// Call this once when the sharing session starts, before any errors can occur.
    public func preloadMetadata() {
        Task { [weak self] in
            guard let self else { return }
            do {
                let documents = try await WalletKitController.instance.fetchAllStorageDocuments()
                let uiCulture = Locale.current.identifier

                var claimNames: [String: String] = [:]
                var docNames: [String: String] = [:]

                for doc in documents {
                    // Document display names
                    let docType = doc.docType
                    if let displayName = doc.getDisplayName(uiCulture),
                       !displayName.isEmpty, !docType.isEmpty {
                        docNames[docType] = displayName
                    }

                    // Claim display names from issuer metadata
                    // This includes ALL possible claims, even optional ones not in the credential
                    if let allDisplayNames = doc.getClaimDisplayNames(uiCulture) {
                        for (_, nsDisplayNames) in allDisplayNames {
                            for (key, name) in nsDisplayNames {
                                claimNames[key] = name
                            }
                        }
                    }
                }

                await MainActor.run {
                    self.claimDisplayNames = claimNames
                    self.documentDisplayNames = docNames
                }
            } catch {
                // Metadata preload is best-effort; on failure the formatter falls back to legacy parsing.
            }
        }
    }

    /// Produce a user-friendly error description from an `PresentationError`.
    /// Tries structured `code` + `context` first; falls back to legacy string parsing on `description`.
    /// Returns `nil` if neither path produces a localized message.
    public func formatError(_ error: PresentationError?) -> String? {
        guard let error else { return nil }

        if let structured = formatStructured(error) {
            return structured
        }

        return formatLegacy(error.description)
    }

    // MARK: - Structured path

    private func formatStructured(_ error: PresentationError) -> String? {
        guard let code = error.code else { return nil }
        switch code {
        case .claimNotFound, .claimValueMismatch, .claimSetNotSatisfied:
            guard let claimPath = error.context["claimPath"] else { return nil }
            return WalletStringKey.sharingErrorClaimNotFound.localized(with: friendlyClaimName(forPath: claimPath))
        case .credentialNotFound:
            guard let docType = error.context["docType"] else { return nil }
            return WalletStringKey.sharingErrorDocumentNotFound.localized(with: friendlyDocumentName(forDocType: docType))
        case .credentialSetNotSatisfied, .dcqlQueryNotSatisfied,
             .bleNotAuthorized, .bleNotSupported,
             .noDocumentsAvailable, .issuerNotRegistered,
             .readerNotTrusted:
            // `.readerNotTrusted` is handled by the presenter (untrustedVerifierAlert) before formatting, so no inline message is needed.
            return nil
        }
    }

    /// Resolve the localized claim name for a `claimPath` string of the form `"<namespace>/<claimKey>"` (mDoc) or `"<vct>/<claimKey>"` (SD-JWT).
    private func friendlyClaimName(forPath claimPath: String) -> String {
        let claimKey = claimPath.split(separator: "/").last.map(String.init) ?? claimPath
        if let displayName = claimDisplayNames[claimKey] {
            return displayName
        }
        return Field<String>.formatDisplayName(from: claimKey)
    }

    /// Resolve the localized document name for a raw docType / vct string.
    private func friendlyDocumentName(forDocType docType: String) -> String {
        if let displayName = documentDisplayNames[docType] {
            return displayName
        }
        if let knownType = WalletDocumentType(rawValue: docType) {
            return knownType.displayName
        }
        return docType
    }

    // MARK: - Legacy path (string parsing)
    // Retained because older upstream sites or third-party wrappers can still surface errors without a populated `code`.
    // The structured path above always takes precedence when available.

    private func formatLegacy(_ rawError: String?) -> String? {
        guard let rawError else { return nil }

        if let claimName = parseClaimNotFound(rawError) {
            return WalletStringKey.sharingErrorClaimNotFound.localized(with: claimName)
        }

        if let docName = parseDocumentNotFound(rawError) {
            return WalletStringKey.sharingErrorDocumentNotFound.localized(with: docName)
        }

        return nil
    }

    /// Parses "Claim not found: eu.europa.ec.eudi.pid.1/family_name_birth"
    /// and returns a friendly display name like "Family Name at Birth".
    private func parseClaimNotFound(_ error: String) -> String? {
        // Pattern: "Claim not found: <namespace>/<claimKey>"
        guard let range = error.range(of: "Claim not found: ") else { return nil }
        let path = String(error[range.upperBound...]).trimmingCharacters(in: .whitespaces)

        // Extract the claim key (after the last "/")
        let claimKey: String
        if let slashIndex = path.lastIndex(of: "/") {
            claimKey = String(path[path.index(after: slashIndex)...])
        } else {
            claimKey = path
        }

        // 1. Try pre-loaded issuer metadata (includes ALL possible claims)
        if let displayName = claimDisplayNames[claimKey] {
            return displayName
        }

        // 2. Fallback: convert snake_case key to human-readable label
        return Field<String>.formatDisplayName(from: claimKey)
    }

    /// Parses "Credential with docType org.iso.18013.5.1.mDL cannot be found."
    /// and returns a friendly display name like "mDL (mDoc)".
    private func parseDocumentNotFound(_ error: String) -> String? {
        // Pattern: "... docType <rawDocType> cannot be found"
        guard let startRange = error.range(of: "docType "),
              let endRange = error.range(of: " cannot be found")
        else { return nil }

        let rawDocType = String(error[startRange.upperBound..<endRange.lowerBound])
            .trimmingCharacters(in: .whitespaces.union(.init(charactersIn: ".")))

        // 1. Try pre-loaded issuer metadata display name
        if let displayName = documentDisplayNames[rawDocType] {
            return displayName
        }

        // 2. Try WalletDocumentType enum mapping
        if let knownType = WalletDocumentType(rawValue: rawDocType) {
            return knownType.displayName
        }

        // 3. Fallback: raw docType as-is
        return rawDocType
    }
}
