# ➕ WalletAddDocument

> The "add a document" entry-point screen. Lists the document types the wallet supports issuing and kicks off the OID4VCI flow for the user's pick.

![Targets: 1](https://img.shields.io/badge/targets-1-blue)
![Layer: Feature](https://img.shields.io/badge/layer-feature-purple)
![Size: small](https://img.shields.io/badge/files-5-lightgrey)
![Pattern: constructor](https://img.shields.io/badge/pattern-constructor-blue)

---

## 🎯 Purpose

`WalletAddDocument` owns the screen the user reaches when they tap "Add document" from the gallery's empty state or from the main menu. It:

1. Reads the configured issuers from `WalletCore.WalletConfiguration` and the document types each issuer publishes in its OID4VCI metadata.
2. Maps those raw upstream offerings into wallet-domain display items (icon, title, subtitle, status badge) via `AddDocumentDocumentTypeMapper`.
3. Renders the list using the constructor system.
4. On tap, either hands off to an OID4VCI URL (and lets the host's deeplink router push the issuance module) or directly opens `DocumentIssuanceModule` from `WalletIssuing`.

The screen is intentionally **read-only of the issuer catalogue** — it doesn't decide which issuer is allowed; that's set up at app launch in `WalletConfiguration`. It also doesn't run the issuance flow itself; that's `WalletIssuing`'s job.

---

## 🧱 Module structure

```
WalletAddDocument/
└── Sources/
    └── WalletAddDocument/
        ├── AddDocumentModule.swift              # BaseModule (factory + presenter + VC)
        ├── AddDocumentPresenter.swift           # MVP presenter
        ├── AddDocumentViewController.swift      # Constructor-VC host
        ├── AddDocumentViewStateFactory.swift    # Builds DSConstructorModel
        └── AddDocumentDocumentTypeMapper.swift  # Maps issuer-offered docs → UI items
```

Five files. The Mapper is the only piece beyond the standard four-file pattern — it deserves a separate file because the mapping logic is non-trivial (per-doc-type display rules, status decisions, icon selection).

---

## 🔌 Public API

### `AddDocumentModule`

```swift
public final class AddDocumentModule: BaseModule {
    public init(
        viewStateFactory: AddDocumentViewStateFactoryProtocol,
        documentTypeMapper: AddDocumentDocumentTypeMapperProtocol,
        qrScannerFactory: QRCodeScannerModuleFactoryProtocol?
    )
    public func viewController() -> UIViewController
}
```

The composition root. Pass the factories the host owns (or stubs in tests). The `qrScannerFactory` is optional — passing `nil` hides the "scan a code" affordance.

### `AddDocumentContentState`

```swift
public enum AddDocumentContentState {
    case loading
    case loaded([AddDocumentItemViewData])
    case empty
    case error(String)
}
```

State enum the view-state factory consumes. The presenter pushes one of these into the factory whenever the underlying data changes.

### `AddDocumentItemViewData`

```swift
public struct AddDocumentItemViewData {
    public let id: String
    public let icon: UIImage?
    public let title: String
    public let subtitle: String?
    public let badge: String?
    public let isEnabled: Bool
}
```

The flat view-row type. One per offered document.

### `AddDocumentDocumentTypeMapperProtocol`

```swift
public protocol AddDocumentDocumentTypeMapperProtocol {
    func map(
        offers: [IssuanceOffer],
        existingDocuments: [Credential]
    ) -> [AddDocumentItemViewData]
}

public struct AddDocumentDocumentTypeMapper: AddDocumentDocumentTypeMapperProtocol {
    public init()
    public func map(offers: [IssuanceOffer], existingDocuments: [Credential]) -> [AddDocumentItemViewData]
}
```

Stateless mapper. Knows that a PID can only be issued once, that an mDL can be re-issued under specific conditions, and that an issuer's offer claims map to icon + title strings via `DocType.displayName`.

### `AddDocumentViewStateFactoryProtocol`

```swift
public protocol AddDocumentViewStateFactoryProtocol {
    func make(state: AddDocumentContentState) -> DSConstructorModel
}

public struct AddDocumentViewStateFactory: AddDocumentViewStateFactoryProtocol {
    public init()
    public func make(state: AddDocumentContentState) -> DSConstructorModel
}
```

Pure function from state → DSConstructorModel. Trivial to unit-test once tests exist.

---

## 🔄 Flow

```
user taps "Add document" in Gallery or Menu
              │
              ▼
  AddDocumentModule presented
              │
              ▼ on viewDidLoad
  presenter.loadOffers()
              │
              │ ── WalletDependencies.walletController.fetchOffers() ─▶ WalletKitProtocol
              │                                                        (returns [IssuanceOffer])
              │
              ▼
  AddDocumentDocumentTypeMapper.map(...) → [AddDocumentItemViewData]
              │
              ▼
  view-state factory renders list
              │
              ▼ user taps a row
  presenter.didSelect(item)
              │
              ▼
  either:                                          or:
    open OID4VCI URL via host deeplink router       open WalletIssuing.DocumentIssuanceModule directly
              │                                                        │
              └────────────────────┬───────────────────────────────────┘
                                   ▼
                         issuance flow proceeds
                         (WalletIssuing owns it)
```

---

## 🌐 Dependencies

| Dependency | Why |
|---|---|
| `DiiaMVPModule` (`ios-mvpmodule`) | MVP scaffolding. |
| `DiiaCommonTypes` (`commontypes`) | Shared protocols. |
| `DiiaCommonServices` (`core-common-services`) | Common services (loading indicators, alerts). |
| `DiiaUIComponents` (`ios-core-uicomponents`) | Constructor UI. |
| [`WalletDocuments`](../WalletDocuments/) (`WalletDocumentsCore`) | Document core types and view primitives. |
| [`WalletCore`](../WalletCore/) (`WalletCore`, `WalletDomainModels`) | `WalletKitProtocol` via `WalletDependencies`, `IssuanceOffer`, `Credential`, `DocType`, `WalletStringKey`. |

No third-party beyond the in-tree Diia OSS packages.

---

## 🗂 Module hierarchy

```text
              ┌────────────────────────────────┐
              │   DiiaGovStackWallet / Gallery  │  callers
              │   (or Menu)                     │
              └──────────────┬─────────────────┘
                             │ open AddDocumentModule
                             ▼
              ┌────────────────────────────────┐
              │      WalletAddDocument          │  ← you are here
              └──────┬─────────────────┬───────┘
                     │                 │
                     ▼                 ▼
              WalletDocuments       WalletCore
              (Core)              (WalletKitProtocol via DI,
                                   IssuanceOffer, DocType)
                     │
                     ▼
              DiiaUIComponents
              (constructor UI, alerts)
```

Layer: **leaf feature** — depends on Core + Documents, depended on by the host and by Gallery/Menu for navigation.

---

## ✅ Guidelines

- **Don't run issuance here.** This screen *selects* what to issue and hands off. The actual OID4VCI exchange is `WalletIssuing.DocumentIssuanceModule`'s job — keep the seam there.
- **Mapper is stateless.** `AddDocumentDocumentTypeMapper` takes offers + existing credentials, returns view items. Don't cache anything across calls; let the presenter own the freshness story.
- **New document types: extend the mapper, not the screen.** When a new `DocType` lands, update `DocType` in `WalletDomainModels` and add the per-type display rule to the mapper. The view-state factory should keep its current shape.
- **No `EudiWalletKit` imports.** The mapper consumes domain types (`IssuanceOffer`, `Credential`) — those are post-engine-bridge types living in `WalletDomainModels`. If you find yourself needing something from `EudiWalletKit`, you're in the wrong layer.
- **QR scanner factory is optional.** Some hosts won't want a scan entry from this screen; passing `nil` should just hide it cleanly, not crash.

---

## 📖 See also

- [`WalletCore/README.md`](../WalletCore/README.md) — `IssuanceOffer`, `WalletKitProtocol`, `WalletDependencies`.
- [`WalletIssuing/README.md`](../WalletIssuing/README.md) — the issuance flow this screen hands off to.
- [`WalletDocuments/README.md`](../WalletDocuments/README.md) — `DocType` and shared document UI primitives.
