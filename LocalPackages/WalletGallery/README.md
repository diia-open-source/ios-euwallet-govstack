# 🖼 WalletGallery

> The wallet's document gallery — PID and mDL cards, deferred-document placeholders, document reordering, and the per-document view-state factories.

![Targets: 1](https://img.shields.io/badge/targets-1-blue)
![Layer: Feature](https://img.shields.io/badge/layer-feature-purple)
![Size: medium](https://img.shields.io/badge/files-22-lightgrey)
![Pattern: constructor + VM cards](https://img.shields.io/badge/pattern-constructor%20%2B%20VM-blue)

---

## 🎯 Purpose

`WalletGallery` is the user's main view of "what's in my wallet". It owns:

- **Per-document card view-state factories** for the two credential types currently supported — **PID** (Personal Identification Document) and **mDL** (mobile Driver's Licence per ISO 18013-5) — plus the **deferred-document placeholder** card shown while an issuer-deferred credential is still pending.
- **Document providers** (`PidDocumentProvider`, `MdlDocumentProvider`) that pull domain credentials out of `WalletKitProtocol` and bind them to card view-models.
- **`DocumentsReorderingModule`** — the drag-to-reorder screen the user reaches from settings.
- **`DocumentReorderingService`** — the persisted-order store on top of `WalletAppStorage`. Reads the saved `[DocType]` order and exposes ordering hooks to the card list.
- **`DocumentsProcessor`** — coordinates revocation status, expiry handling, and stack-vs-flat presentation mode for the gallery.

The gallery itself (the scrollable card list) is rendered by the host's `DocumentsCollection` flow (which lives in `DiiaGovStackWallet/Common/Documents/`). This package supplies the per-card view-state factories that flow plugs in.

---

## 🧱 Module structure

```
WalletGallery/
└── Sources/
    └── WalletGallery/
        ├── Configuration/
        │   └── WalletGalleryConfiguration.swift           # WalletGalleryConfiguration (images + flags)
        ├── DocumentsReordering/
        │   ├── DocumentsReorderingDocumentsProvider.swift # Provides reorder-eligible doc list
        │   ├── DocumentsReorderingDocumentsProviderProtocol.swift
        │   ├── DocumentsReorderingModule.swift            # BaseModule
        │   ├── DocumentsReorderingPresenter.swift         # Constructor presenter
        │   ├── DocumentsReorderingViewStateFactory.swift  # DSConstructorModel
        │   ├── DocumentsReorderingConstructorComponents.swift
        │   └── View/
        │       ├── DocReorderingCellInfoView.swift        # Per-row chrome
        │       ├── DocumentReorderingCell.swift           # Reorderable cell
        │       └── MultipleDocReorderingView.swift        # List view
        ├── Factories/
        │   ├── PidDocumentViewStateFactory.swift          # PID card factory
        │   ├── MdlDocumentViewStateFactory.swift          # mDL card factory
        │   └── DeferredDocumentViewStateFactory.swift     # Deferred placeholder factory
        ├── Services/
        │   ├── DocumentsProcessor.swift                   # Status + expiry coordinator
        │   ├── DocumentReorderingService.swift            # Persisted-order store
        │   └── DocumentProviders/
        │       ├── DocumentModelProvider.swift            # Provider protocol
        │       ├── PidDocumentProvider.swift              # PID provider impl
        │       └── MdlDocumentProvider.swift              # mDL provider impl
        ├── Utility/
        │   └── DocumentExpiryResolver.swift               # Expiry status (valid/expiring/expired)
        └── ViewModels/
            ├── PidCardViewModel.swift                     # PID card view model
            ├── MdlCardViewModel.swift                     # mDL card view model
            └── DeferredDocumentViewModel.swift            # Deferred card view model
```

22 files across six logical areas: configuration, reordering, factories, services, utility, view models.

---

## 🔌 Public API

### `WalletGalleryConfiguration`

```swift
public enum WalletGalleryConfiguration {
    public static func configure(images: WalletGalleryImages)
    public static var images: WalletGalleryImages { get }
}

public struct WalletGalleryImages {
    public let documentInfo: UIImage
    public let deleteDocument: UIImage
    /* …additional themable images… */
    public init(/* … */)
}
```

A namespace-style configuration enum the host calls at launch (`WalletGalleryConfiguration.configure(images:)` from `AppConfigurator.swift`) to inject the asset-catalogue images the per-card factories need (info icon, delete icon, etc.). Keeps image asset references out of the SPM bundle.

### `PidDocumentViewStateFactory`, `MdlDocumentViewStateFactory`, `DeferredDocumentViewStateFactory`

Each factory is the view-state builder for its credential type:

```swift
public protocol PidDocumentViewStateFactoryProtocol {
    func make(model: PidCardViewModel) -> DSConstructorModel
}

public struct PidDocumentViewStateFactory: PidDocumentViewStateFactoryProtocol {
    public init()
    public func make(model: PidCardViewModel) -> DSConstructorModel
}
```

Pure mappers — no state, no I/O. The presenter calls the factory whenever the underlying view-model changes.

### `DocumentsReorderingModule`

```swift
public final class DocumentsReorderingModule: BaseModule {
    public init(/* injected provider, service, factory */)
    public func viewController() -> UIViewController
}
```

The reorder screen. Drag-and-drop one card at a time; the order is persisted via `DocumentReorderingService` on confirmation.

### `DocumentsProcessor`

```swift
public final class DocumentsProcessor {
    public init(/* injected dependencies */)
    public func process(documents: [Credential]) -> [DocumentDisplay]
}
```

The orchestration layer between domain credentials and per-card view models. Applies revocation status (via `DocumentRevocationService` in `WalletCore`), resolves expiry via `DocumentExpiryResolver`, decides which credentials are stack-mode vs flat-mode, and produces the `[DocumentDisplay]` array the host's gallery consumes.

### `DocumentReorderingService`

```swift
public final class DocumentReorderingService {
    public static let shared: DocumentReorderingService
    public func docTypesOrder() -> [DocTypeCode]
    public func setOrder(order: [DocTypeCode], synchronize: Bool)
    public func order(for type: DocTypeCode) -> [String]
}
```

Singleton (today; injectable via the protocol if needed) backed by `WalletAppStorage.StoreHelper` with `StoringKey.docsOrder` / `.docsStackOrder` / `.docsFlatOrder`. Order is deduplicated on read to defend against corrupted stored arrays.

---

## 🃏 The card pipeline

```
WalletKitProtocol.loadDocuments() → [Credential]
              │
              ▼  DocumentsProcessor.process(documents:)
   per credential:
     │
     ├──▶ DocumentRevocationService → revocation status
     ├──▶ DocumentExpiryResolver  → expiry status
     └──▶ DocumentReorderingService → display order
              │
              ▼
   [DocumentDisplay]                        (host's DocumentsCollection consumes this)
              │
              ▼  per-document, select the right ViewModel/Factory pair:
              │
              ├──▶ DocType.pid:       PidCardViewModel  → PidDocumentViewStateFactory
              ├──▶ DocType.mdl:       MdlCardViewModel  → MdlDocumentViewStateFactory
              └──▶ isDeferred:        DeferredDocumentViewModel → DeferredDocumentViewStateFactory
              │
              ▼
   DSConstructorModel
              │
              ▼
   rendered in the gallery's ConstructorViewController
```

Adding a new document type means three additions:

1. A new `DocType` case in `WalletDomainModels`.
2. A new `<Type>CardViewModel` + `<Type>DocumentViewStateFactory` pair in this package (parallel to PID/mDL).
3. A new `<Type>DocumentProvider` in `Services/DocumentProviders/` that knows how to bind a `Credential` of that type to the new view model.

---

## 🌐 Dependencies

| Dependency | Why |
|---|---|
| `ReactiveKit` | Observation in card view models. |
| `DiiaMVPModule` | MVP scaffolding. |
| `DiiaCommonTypes` | Shared protocols. |
| `DiiaUIComponents` | Constructor UI. |
| [`WalletDocuments`](../WalletDocuments/) (`WalletDocumentsCore`, `WalletDocumentsCommonTypes`) | `DocumentAttributesProtocol`, `DocumentModel`, `DocumentStatusCode`, the document-collection chrome. |
| [`WalletAppStorage`](../WalletAppStorage/) | `StoreHelper` + `StoringKey.docs*Order` for persisted ordering. |
| [`WalletCore`](../WalletCore/) (`WalletCore` + `WalletDomainModels`) | `WalletKitProtocol`, `Credential`, `DocType`, `EudiPidDocumentModel`, `EudiMdlDocumentModel`, `WalletStringKey`. |

---

## 🗂 Module hierarchy

```text
              ┌────────────────────────────────┐
              │   DiiaGovStackWallet            │
              │   DocumentsCollection (host)    │
              └──────────────┬─────────────────┘
                             │ consumes factories + service
                             ▼
              ┌────────────────────────────────┐
              │       WalletGallery             │  ← you are here
              │ Factories + Services + VMs      │
              └────┬────────────┬───────────────┘
                   │            │
        ┌──────────┘            └──────────────┐
        ▼                                       ▼
  WalletDocuments                          WalletCore +
  (Core + CommonTypes)                     WalletAppStorage
  (document chrome,                        (ports, persisted order)
   collection cells)
```

Layer: **feature with several internal services** — depended on by the host's DocumentsCollection, depends on Documents + Core + AppStorage.

---

## ✅ Guidelines

- **Card view-state factories are pure.** The factory takes a view-model, returns a `DSConstructorModel`. No reads from disk, no calls into `WalletDependencies`. Domain decisions happen earlier in the pipeline (`DocumentsProcessor` / provider).
- **Image asset injection via `WalletGalleryConfiguration.configure(images:)` is mandatory.** Without it, the cards crash on first render because info/delete icons resolve to `nil`. The host's `AppConfigurator.swift` does this once at launch.
- **Order persistence is deduplicating-on-read.** A corrupted `[DocType]` array in user defaults (e.g. duplicate entries from a previous version's bug) is silently cleaned up by `docTypesOrder()` before it reaches the UI. Don't relax this.
- **Adding a document type:** keep the parallelism — one view model + one factory + one provider, mirroring PID/mDL. Avoid a generic "any document" factory; the per-type shape is intentional so display rules stay local.
- **Deferred placeholder lives here too.** Users see a deferred-document card while issuer-deferred credentials are pending — this is the gallery's responsibility, not `WalletIssuing`'s. The poller (`DeferredIssuanceCoordinator` in `WalletIssuing`) just decides when the deferred state ends; the card UI is here.
- **No `EudiWalletKit` imports.** Domain types only — `Credential`, `EudiPidDocumentModel`, `EudiMdlDocumentModel` all live in `WalletDomainModels`.

---

## 📖 See also

- [`WalletCore/README.md`](../WalletCore/README.md) — `Credential`, `DocType`, `WalletKitProtocol`, `DocumentRevocationService`.
- [`WalletDocuments/README.md`](../WalletDocuments/README.md) — `DocumentAttributesProtocol`, document chrome.
- [`WalletAppStorage/README.md`](../WalletAppStorage/README.md) — `StoringKey.docs*Order`.
- [`WalletIssuing/README.md`](../WalletIssuing/README.md) — the deferred-issuance polling that updates the deferred card's state.
