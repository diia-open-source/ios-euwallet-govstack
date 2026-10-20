//
//  WalletErrorFormatting.swift
//

import Foundation
import WalletDomainModels

/// Domain-facing port for turning wallet errors into user-friendly localized strings.
///
/// The concrete implementor (`WalletErrorFormatter`) preloads claim/document display names from issuer metadata and converts `PresentationError` instances — populated by the SDK boundary, see `WalletError+Domain.swift` — into the right localized message.
///
/// Features depend on this protocol via `WalletDependencies.walletErrorFormatter` so they never touch the concrete (which imports EudiWalletKit / WalletStorage).
/// Phase H moves the concrete impl into WalletEngine; this protocol stays here.
///
/// Signatures take only domain types (`PresentationError?`).
public protocol WalletErrorFormatting {
    /// Pre-load claim and document display names from the issuer's credential metadata.
    /// Call once when a sharing session starts, before any errors can surface.
    /// Implementations are expected to be non-blocking (fire-and-forget Task internally).
    func preloadMetadata()

    /// Produce a user-friendly error description from an `PresentationError`.
    /// Tries structured `code` + `context` first; falls back to legacy string parsing.
    /// Returns `nil` if neither path yields a localized message.
    func formatError(_ error: PresentationError?) -> String?
}
