import Foundation
import WalletCore
import WalletDomainModels

/// Bridges `WalletCore`'s `WalletStringKey` to the app's hand-maintained `R.Strings` table.
///
/// `WalletStringKey.rawValue` matches the corresponding `R.Strings` case rawValue,
/// so resolution is a single `R.Strings(rawValue:)` lookup — no per-key switch.
struct AppWalletStringsProvider: WalletStringsProviding {
    func localizedString(for key: WalletStringKey) -> String {
        guard let rString = R.Strings(rawValue: key.rawValue) else {
            assertionFailure("WalletStringKey.\(key) (\(key.rawValue)) has no matching R.Strings case — the two enums are out of sync.")
            return key.rawValue
        }
        return rString.localized()
    }

    func localizedString(for key: WalletStringKey, with argument: String) -> String {
        guard let rString = R.Strings(rawValue: key.rawValue) else {
            assertionFailure("WalletStringKey.\(key) (\(key.rawValue)) has no matching R.Strings case — the two enums are out of sync.")
            return key.rawValue
        }
        return rString.localized(with: argument)
    }
}
