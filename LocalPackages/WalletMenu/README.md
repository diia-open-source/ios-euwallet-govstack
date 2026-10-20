# 📋 WalletMenu

> The wallet's settings and main-menu screens. Hub from which the user reaches authorization, document order, biometry toggle, transaction history, support, and sign-out.

![Targets: 1](https://img.shields.io/badge/targets-1-blue)
![Layer: Feature](https://img.shields.io/badge/layer-feature-purple)
![Size: medium](https://img.shields.io/badge/files-10-lightgrey)
![Pattern: constructor](https://img.shields.io/badge/pattern-constructor-blue)

---

## 🎯 Purpose

`WalletMenu` owns the two related screens that surface user-controlled settings and navigation:

- **Main menu** (`MenuModule`) — the top-level menu the user reaches from the tab bar. Lists entries such as "Settings", "Document order", "Transaction history", "Support", "About", "Sign out". Each entry is a `MenuFlowProviding`-routed action.
- **Settings** (`SettingsModule`) — the sub-screen with PIN-change, biometry toggle, language, and other toggle/value rows.

The screens are deliberately thin. They render a `DSConstructorModel` populated by their view-state factories and route taps via a per-screen action enum. Heavy lifting (auth flows, biometry permission, transaction list) lives in other SPMs — this package just routes.

A `MenuFlowProviding` protocol (declared here) lets the host inject the routing decisions (e.g. "where does 'Sign out' go?") rather than encoding them in the presenter. This is the canonical reference module for the project.

---

## 🧱 Module structure

```
WalletMenu/
└── Sources/
    └── WalletMenu/
        ├── Common/
        │   └── MenuFlowProviding.swift                   # Router-injection protocol
        ├── Main/
        │   ├── MenuModule.swift                          # Main menu module
        │   ├── MenuPresenter.swift                       # ConstructorScreenPresenter
        │   └── MenuViewStateFactory.swift                # Main menu DSConstructorModel
        └── Settings/
            ├── IconSwitchRowConstructorComponent.swift   # Custom toggle row component
            ├── SettingsConstructorComponents.swift       # Settings descriptors
            ├── SettingsItemsMapper.swift                 # Settings state → items
            ├── SettingsModule.swift                      # Settings module
            ├── SettingsPresenter.swift                   # ConstructorScreenPresenter
            └── SettingsViewStateFactory.swift            # Settings DSConstructorModel
```

Ten files split into `Common/`, `Main/`, and `Settings/`. The `Settings/` subfolder is larger because settings carries one custom DS component (`IconSwitchRowConstructorComponent`) that this module owns rather than pushing back into `DiiaUIComponents`.

---

## 🔌 Public API

### `MenuModule`

```swift
public final class MenuModule: BaseModule {
    public init(
        flowProvider: MenuFlowProviding,
        viewStateFactory: MenuViewStateFactoryProtocol
    )
    public func viewController() -> UIViewController
}
```

The main menu. Routes every entry through the injected `MenuFlowProviding`. The view-state factory builds the row list from the host-provided menu items.

### `SettingsModule`

```swift
public final class SettingsModule: BaseModule {
    public init(/* injected dependencies */)
    public func viewController() -> UIViewController
}
```

The settings sub-screen. Owns toggle state for biometry (delegates to `WalletAuthorization` for the actual enable/disable) and language (when a second locale is enabled). Reads/writes go through `WalletDependencies` and `WalletAppStorage.StoreHelper`.

### `MenuFlowProviding`

```swift
public protocol MenuFlowProviding {
    func openSettings(from view: BaseView)
    func openTransactionHistory(from view: BaseView)
    func openDocumentOrder(from view: BaseView)
    func openSupport(from view: BaseView)
    func openAbout(from view: BaseView)
    func signOut(from view: BaseView)
    // …
}
```

The router protocol the host implements in `AppMenuFlowProvider`. Keeps `MenuPresenter` decoupled from concrete module construction — the host knows where things go.

### `MenuViewStateFactoryProtocol`

```swift
public protocol MenuViewStateFactoryProtocol {
    func make(items: [MenuItem]) -> DSConstructorModel
}

public struct MenuViewStateFactory: MenuViewStateFactoryProtocol {
    public init()
}
```

Pure mapper from menu-item domain to constructor model.

---

## 🧩 Why this is the reference module

`WalletMenu/Main/` is the canonical example:

```
WalletMenu/Main/
├── MenuModule.swift            # Assembly
├── MenuPresenter.swift         # ConstructorScreenPresenter subclass
└── MenuViewStateFactory.swift  # Pure factory
```

Three small files. No subclassing of `ConstructorViewController`. No `UIView` work in the presenter beyond `view.setupBackground(...)`. Component keys are sourced from each builder's `static var key`. If you need a starting point for a new screen, copy this layout.

---

## 🔄 Flow

```
user lands on tab bar → "Menu" tab
              │
              ▼
   MenuModule presented
              │
              ▼  on configureView
   MenuPresenter pulls menu items from host (via MenuFlowProviding contract)
              │
              ▼  MenuViewStateFactory.make(items:)
   DSConstructorModel rendered
              │
              ▼  user taps a row
   MenuPresenter.didSelect(MenuAction)
              │  switch on action enum:
              │
              ├──▶ flowProvider.openSettings(from: view)        → SettingsModule
              ├──▶ flowProvider.openTransactionHistory(...)     → WalletTransaction
              ├──▶ flowProvider.openDocumentOrder(...)          → host's reordering screen
              ├──▶ flowProvider.openSupport(...)                → host's support screen
              ├──▶ flowProvider.signOut(...)                    → WalletAuthorization
              └──▶ …
```

Routing is symmetric: every menu entry is a `MenuAction` enum case + a `MenuFlowProviding` method. Adding a new entry is two lines + one method.

---

## 🌐 Dependencies

| Dependency | Why |
|---|---|
| `DiiaMVPModule` | MVP scaffolding. |
| `DiiaCommonTypes` | Shared protocols. |
| `DiiaCommonServices` | Common services. |
| `DiiaUIComponents` | Constructor UI. |
| [`WalletAuthorization`](../WalletAuthorization/) | `WalletAuthorizationPinCode` product — for the change-pin entry from settings + biometry toggle. |
| [`WalletTransaction`](../WalletTransaction/) | `TransactionsModule` for the "Transaction history" entry. |
| [`WalletCore`](../WalletCore/) | `WalletKitProtocol` via DI, `WalletStringKey`. |

No persistence dependencies (it reads/writes through `WalletDependencies` and `StoreHelper`-shaped APIs exposed by other packages).

---

## 🗂 Module hierarchy

```text
              ┌────────────────────────────────┐
              │   DiiaGovStackWallet            │
              │   MainTabBar host shell         │
              └──────────────┬─────────────────┘
                             │ presents MenuModule
                             ▼
              ┌────────────────────────────────┐
              │         WalletMenu              │  ← you are here
              │   MenuModule  SettingsModule    │
              └──┬─────────┬────────┬──────────┘
                 │         │        │
                 ▼         ▼        ▼
        WalletAuthorization   WalletTransaction   WalletCore
        (pin change, biometry)  (history)         (strings, port)
```

Layer: **leaf feature** — depends on several other features, depended on only by the host shell.

---

## ✅ Guidelines

- **Routing decisions live in the host.** The host's `AppMenuFlowProvider` implements `MenuFlowProviding`. Do not hardcode module construction inside `MenuPresenter` — that would couple this package to every feature it links to.
- **Settings toggles delegate.** "Biometry on/off" doesn't mutate state from this presenter — it asks `WalletAuthorization` to validate the prerequisite (PIN + Face ID/Touch ID available) and applies the result via `StoreHelper`. Keep `SettingsPresenter` thin.
- **Custom DS components stay local.** `IconSwitchRowConstructorComponent` lives in this package. Move it into `DiiaUIComponents` only if a second screen needs it; until then, premature promotion just inflates the shared library.
- **Adding a menu entry:** add a `MenuAction` case, a `MenuFlowProviding` method, an item in the host's menu config. The view-state factory should pick it up via the items array without further changes.
- **No `EudiWalletKit` imports.** This is a routing surface; nothing here should know about the engine.

---

## 📖 See also

- [`DiiaGovStackWallet/Common/Services/AppMenuFlowProvider.swift`](../../DiiaGovStackWallet/Common/Services/AppMenuFlowProvider.swift) — host implementation of `MenuFlowProviding`.
- [`WalletAuthorization/README.md`](../WalletAuthorization/README.md) — the PIN/biometry flows the settings screen delegates to.
