import Foundation

/// Supplies localized values for `WalletStringKey` to `WalletCore`.
///
/// The package never resolves strings itself; the consuming app installs a provider
/// at launch via `WalletStrings.configure(_:)` so the app stays the single owner of
/// `Localizable.strings` and any locale-specific behavior.
public protocol WalletStringsProviding {
    func localizedString(for key: WalletStringKey) -> String
    func localizedString(for key: WalletStringKey, with argument: String) -> String
    func localizedString(for key: WalletStringKey, arguments: [CVarArg]) -> String
}

public extension WalletStringsProviding {
    /// Default format-argument behavior mirrors `R.Strings.x.localized(with:)` in the host app:
    /// the localized value is treated as a printf-style format string with one substitution.
    func localizedString(for key: WalletStringKey, with argument: String) -> String {
        String(format: localizedString(for: key), argument)
    }

    /// Default vararg behavior mirrors `R.Strings.x.formattedLocalized(arguments:)`:
    /// the localized value is treated as a printf-style format string applied to the array.
    func localizedString(for key: WalletStringKey, arguments: [CVarArg]) -> String {
        String(format: localizedString(for: key), arguments)
    }
}

/// Global access point for wallet-package strings.
///
/// Must be configured exactly once at app launch, before any factory or controller
/// that uses `WalletStringKey.localized()` runs.
public enum WalletStrings {
    public static func configure(_ provider: WalletStringsProviding) {
        _provider = provider
    }

    public static func localized(_ key: WalletStringKey) -> String {
        provider.localizedString(for: key)
    }

    public static func localized(_ key: WalletStringKey, with argument: String) -> String {
        provider.localizedString(for: key, with: argument)
    }

    public static func localized(_ key: WalletStringKey, arguments: [CVarArg]) -> String {
        provider.localizedString(for: key, arguments: arguments)
    }

    private static var _provider: WalletStringsProviding?

    private static var provider: WalletStringsProviding {
        guard let provider = _provider else {
            fatalError("WalletStrings accessed before WalletStrings.configure(_:) was called — bootstrap the wallet strings provider at app launch.")
        }
        return provider
    }
}

public extension WalletStringKey {
    func localized() -> String { WalletStrings.localized(self) }
    func localized(with argument: String) -> String { WalletStrings.localized(self, with: argument) }
    func formattedLocalized(arguments: CVarArg...) -> String { WalletStrings.localized(self, arguments: arguments) }
}
