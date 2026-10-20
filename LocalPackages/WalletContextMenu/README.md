# 📍 WalletContextMenu

> Reusable context-menu / action-sheet provider used by screens that need to surface secondary actions from a header navigation panel.

![Targets: 1](https://img.shields.io/badge/targets-1-blue)
![Layer: Feature primitive](https://img.shields.io/badge/layer-feature%20primitive-purple)
![Size: tiny](https://img.shields.io/badge/files-2-lightgrey)

---

## 🎯 Purpose

`WalletContextMenu` is the small shared module that gives wallet screens a uniform way to render a navigation-bar context menu (the `…` overflow button) as an `ActionSheetModule` populated from a list of typed `ContextMenuItem`s.

Without this module, every screen that wanted an overflow menu would either:

- duplicate the same "build action sheet from items, present via `view.showChild(module:)`" wiring across feature SPMs, or
- pull `ActionSheetModule` plumbing into each presenter and re-derive item-to-action mapping.

Instead, feature presenters hold a `ContextMenuProviderProtocol` (defined in `DiiaCommonTypes`) and lean on this package's `BaseContextMenuProvider` as the default implementation. A `ContextMenuConfigurable` mix-in is provided for `ConstructorScreenPresenter` subclasses that want to derive the menu state from a `DSConstructorModel`'s navigation panel automatically.

---

## 🧱 Module structure

```
WalletContextMenu/
└── Sources/
    └── WalletContextMenu/
        ├── BaseContextMenuProvider.swift   # Default provider implementation
        └── ContextMenuConfigurable.swift   # Mix-in for ConstructorScreenPresenter
```

Two files. The whole module is intentionally minimal — it exists so callers don't reinvent the same five lines of code, not because the behaviour is intricate.

---

## 🔌 Public API

### `BaseContextMenuProvider`

```swift
public struct BaseContextMenuProvider: ContextMenuProviderProtocol {
    public var title: String?

    public init(title: String? = nil, items: [ContextMenuItem] = [])

    public func hasContextMenu() -> Bool
    public func openContextMenu(in view: BaseView)
    public mutating func setContextMenu(items: [ContextMenuItem]?)
    public mutating func setTitle(title: String?)
}
```

Holds an array of `ContextMenuItem`s and exposes the `ContextMenuProviderProtocol` (declared in `DiiaCommonTypes`) that wallet presenters consume. `openContextMenu(in:)` converts items into `Action` arrays and presents an `ActionSheetModule` as a child of the given view.

Currently the only item type the provider knows how to render is `.supportServiceScreen`, which presents a `HorizontalActionSheetModule` titled with `WalletStringKey.menuSupport`. New `ContextMenuItem.Type` cases that need bespoke rendering go in `prepareAction(for:in:)`.

### `ContextMenuConfigurable`

```swift
public protocol ContextMenuConfigurable {
    var view: ConstructorScreenViewProtocol { get set }
}

public extension ContextMenuConfigurable {
    func updateContextMenu(
        model: DSConstructorModel,
        in contextMenuProvider: inout ContextMenuProviderProtocol
    )
}
```

A protocol-extension helper meant to be conformed to by `ConstructorScreenPresenter` subclasses. The default `updateContextMenu(model:in:)` pulls the navigation-panel section out of a `DSConstructorModel`, derives the appropriate items, and mutates the inout provider.

Use this from presenters that already render their state via a `DSConstructorModel` — wallet feature presenters typically do.

---

## 📂 Where it's used

Currently consumed by [`WalletIssuing`](../WalletIssuing/) — issuance flows surface a "Support" entry in the navigation overflow during onboarding and document issuance.

The module is structured so any wallet screen with a `ConstructorScreenViewProtocol`-shaped view can adopt it — adoption is a `BaseContextMenuProvider()` property + a single `updateContextMenu(model:in:&provider)` call per render.

---

## 🌐 Dependencies

| Dependency | Why |
|---|---|
| `DiiaMVPModule` | `BaseView`, `BasePresenter` plumbing for the action-sheet hosting. |
| `DiiaCommonTypes` | `ContextMenuProviderProtocol`, `ContextMenuItem`, `Action`. |
| `DiiaUIComponents` | `ConstructorScreenViewProtocol`, `DSConstructorModel`, `ActionSheetModule`, `HorizontalActionSheetModule`. |
| [`WalletCore`](../WalletCore/) | `WalletStringKey` (localized strings for the "Support" label). |

No third-party dependencies. No persistence. No background work.

---

## 🗂 Module hierarchy

```text
┌──────────────────────────────────────────┐
│            Feature presenters             │
│ (WalletIssuing, possibly others later)    │
└──────────────────┬───────────────────────┘
                   │ holds ContextMenuProviderProtocol
                   ▼
        ┌───────────────────────────┐
        │  WalletContextMenu         │  ← you are here
        │  (BaseContextMenuProvider, │
        │   ContextMenuConfigurable) │
        └────────┬──────────┬───────┘
                 │          │
                 ▼          ▼
        ConstructorScreenViewProtocol
        ActionSheetModule  HorizontalActionSheetModule
        (all DiiaUIComponents)
```

Layer: **feature primitive** — small reusable bridge between domain context (which items make sense) and UI presentation (action sheet).

Imported by: `WalletIssuing` (today). Easy to adopt elsewhere.

Imports: `DiiaMVPModule`, `DiiaCommonTypes`, `DiiaUIComponents`, `WalletCore`.

---

## ✅ Guidelines

- **Add new `ContextMenuItem.Type` cases at the call site first, not in the provider.** The `ContextMenuItem` and its enum live in `DiiaCommonTypes` (upstream). If a wallet-specific item type is needed, prefer a thin wrapper or extension over modifying upstream.
- **Don't add navigation logic here.** This package converts intent into action-sheet UI. Where the user goes after picking an action is the caller's responsibility — pass a `[weak view]` closure in the `Action.callback` and resolve the destination in the presenter.
- **Keep `ContextMenuConfigurable` opt-in.** Not every presenter wants its overflow menu auto-derived from the constructor model. The mix-in is sugar; the bare provider works without it.
- **No `EudiWalletKit` imports.** This module sits on the feature side of the architecture; nothing here needs `WalletEngine` or any EUDI symbol.
- **Don't grow the file count without a reason.** This module is intentionally tiny — keep it tiny. If you find yourself adding a third file, ask whether the new concern really belongs here or somewhere already-domain-aware.

---

## 📖 See also

- `DiiaCommonTypes.ContextMenuProviderProtocol` — the upstream protocol this module implements.
- [`WalletIssuing/Sources/WalletIssuing/DocumentIssuance/`](../WalletIssuing/Sources/WalletIssuing/DocumentIssuance/) — example call site.
- [`WalletCore/README.md`](../WalletCore/README.md) for `WalletStringKey` localization.
