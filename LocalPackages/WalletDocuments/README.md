# 📄 WalletDocuments

> The shared document domain layer. Two targets: pure types and view primitives (`WalletDocumentsCommonTypes`) and the full document-collection module (`WalletDocumentsCore`).

![Targets: 2](https://img.shields.io/badge/targets-2-blue)
![Layer: Domain + Feature](https://img.shields.io/badge/layer-domain%20%2B%20feature-orange)
![Size: large](https://img.shields.io/badge/files-49-lightgrey)

---

## 🎯 Purpose

`WalletDocuments` is the shared document layer every credential-aware feature module depends on. It defines:

- **Document attributes** — `DocumentAttributesProtocol`, `DocumentStackIconAppearance`, `DocumentStatusCode`, `DocumentsMode` — the value types every screen agrees on when it talks about "a document".
- **Document chrome** — the design-system views that render a document card: the photo card, the QR/barcode pair, the verification view, the "add new document" placeholder.
- **`DocumentDetailsCommonModule`** — the generic per-document detail screen used as the base by feature-specific details flows.
- **`DocumentActionSheetModule`** — the consistent action sheet (delete, info, share, etc.) the gallery and details screens both reach for.
- **`ActivatePidDocumentViewModel`, `DSPidActivateCardView`** — the activation card and view model shown while a PID is being initialized.
- **`DocumentsQRPlaceholderView`** — the placeholder shown until a document QR is ready (used by `WalletSharing.DocumentsQR`).

The package is split into two targets so feature modules can depend on the pure types layer without dragging in the larger Core layer.

---

## 🧱 Targets

```
WalletDocuments (package)
├── WalletDocumentsCommonTypes   pure types, protocols, models, primitive views, R+
└── WalletDocumentsCore          document collection module, details flow, action sheet
```

### `WalletDocumentsCommonTypes`

The leaf. Contains:

- **Models**: `DocumentModel` (protocol), `DocumentStatusCode`, `DocumentStackIconAppearance`, `DocumentsMode`, `CodedNamedValueModel`, `DocToAddModel`, `MultiDataType`, `QRCodeViewModel`, `ShareLinkModel`, `ShareVerificationCodesModel`.
- **Protocols**: `DocumentAttributesProtocol`, `DocumentCollectionHolderProtocol`, `DocumentsReservePhotoServiceProtocol`, `SharingDocsApiClientProtocol`, `StatusedExpirableProtocol`.
- **Design system**: `DSFullDocumentModel`, `DSDocumentWithPhotoView`/`ViewModel`, `DSDocumentState`.
- **Views**: `QRCodeBarcodeView`, `VerificationView`, `VerificationOptionView`.
- **Configuration**: `DocumentsCommonConfiguration` — host-injected images and behaviour flags.
- **Resources**: `R.Strings`, `R.Image` enums + per-target `.strings`/asset catalogue.

This target is consumed by `WalletDomainModels` (for `DocumentAttributesProtocol`-bound types): `DocType` in `WalletDomainModels` conforms to `DocumentAttributesProtocol`, so the conformance pulls this target into the domain layer's dependency closure.

### `WalletDocumentsCore`

The full document feature surface. Contains:

- **`DocumentsCollection*`** — the gallery list module, presenter, view-state factory. The presenter coordinates with `DocumentsCollectionContext` (host-supplied) to handle add/delete/reorder navigation.
- **`DocumentDetailsCommon*`** — the generic detail screen (Module + Presenter + ViewController + ViewStateFactory + ViewModel).
- **`DocumentActionSheet*`** — the per-document action sheet.
- **`ActivatePidDocumentViewModel`, `DSPidActivateCardView`** — PID activation chrome.
- **`AddNewDocumentView`** — the empty-state row.
- **`DocumentsQRPlaceholderView`** — public placeholder used by `WalletSharing`.
- **`DocumentReorderingServiceProtocol`** — the order-persistence port consumed by `WalletGallery.DocumentReorderingService`.
- **`AddDocumentsService`** — small coordinator wired by the host.

---

## 🧱 Module structure (abbreviated)

```
WalletDocuments/
└── Sources/
    ├── WalletDocumentsCommonTypes/
    │   ├── DesignSystem/
    │   │   ├── Models/DSFullDocumentModel.swift
    │   │   └── Views/DSDocumentWithPhotoView.swift
    │   ├── DocumentsCommonConfiguration.swift
    │   ├── DocumentsConstants.swift
    │   ├── Models/
    │   │   ├── DocumentModel.swift
    │   │   ├── DocumentStackIconAppearance.swift
    │   │   ├── DocumentStatusCode.swift
    │   │   ├── DocumentsMode.swift
    │   │   ├── QRCodeViewModel.swift
    │   │   ├── ShareLinkModel.swift
    │   │   ├── ShareVerificationCodesModel.swift
    │   │   ├── CodedNamedValueModel.swift
    │   │   └── DocToAddModel.swift
    │   ├── MultiDataType.swift
    │   ├── Protocols/
    │   │   ├── DocumentAttributesProtocol.swift
    │   │   ├── DocumentCollectionHolderProtocol.swift
    │   │   ├── DocumentsReservePhotoServiceProtocol.swift
    │   │   ├── SharingDocsApiClientProtocol.swift
    │   │   └── StatusedExpirableProtocol.swift
    │   ├── Resources/
    │   │   ├── R+Images.swift
    │   │   └── R+Strings.swift
    │   └── Views/
    │       ├── QRCodeBarcodeView.swift
    │       ├── VerificationOptionView.swift
    │       └── VerificationView.swift
    └── WalletDocumentsCore/
        ├── Common/
        │   ├── Protocols/
        │   │   ├── DocumentReorderingServiceProtocol.swift
        │   │   └── DocumentsProvider.swift
        │   ├── Services/AddDocumentsService.swift
        │   └── Views/
        │       ├── ActivatePidDocumentViewModel.swift
        │       ├── AddNewDocumentView/
        │       │   ├── AddNewDocumentView.swift
        │       │   └── AddNewDocumentViewModel.swift
        │       ├── DSPidActivateCardView.swift
        │       └── DocumentCollectionCell.swift
        └── Modules/
            ├── DocumentActionSheet/
            │   ├── DocumentActionSheetModule.swift
            │   └── DocumentActionSheetViewController.swift
            ├── DocumentDetailsCommon/
            │   ├── DocumentDetailsCommonModule.swift
            │   ├── DocumentDetailsCommonPresenter.swift
            │   ├── DocumentDetailsCommonViewController.swift
            │   ├── DocumentDetailsCommonViewStateFactory.swift
            │   └── ViewModel/DocumentDetailsCommonViewModel.swift
            └── DocumentsCollection/
                ├── DocumentsCollectionModule.swift
                ├── DocumentsCollectionPresenter.swift
                └── …
```

49 files total. The largest feature package; second-largest local package after the in-tree `ios-core-uicomponents`.

---

## 🔌 Public API highlights

### `DocumentAttributesProtocol`

```swift
public protocol DocumentAttributesProtocol {
    var rawValue: String { get }
    var icon: UIImage? { get }
    var stackIconAppearance: DocumentStackIconAppearance { get }
    /* … */
}
```

The protocol every domain `DocType`-like enum conforms to. `WalletDomainModels.DocType` conforms to this, which is why `WalletDomainModels` depends on `WalletDocumentsCommonTypes`.

### `DocumentStatusCode`, `DocumentStackIconAppearance`, `DocumentsMode`

Lightweight enums (`Codable`, often `Equatable`) used end-to-end across the gallery / details / sharing flows.

### `DSDocumentWithPhotoView`, `DSDocumentWithPhotoViewModel`

The design-system "photo card" — the canonical document card chrome with a photo, header, footer, and status badge. The PID and mDL cards both render through this view.

### `DocumentsCollectionModule`

```swift
public final class DocumentsCollectionModule: BaseModule {
    public init(/* injected DocumentsCollectionContext */)
    public func viewController() -> UIViewController
}
```

The gallery list — the screen the user sees inside the "Documents" tab. The host supplies a `DocumentsCollectionContext` describing how to add documents, where to navigate on tap, etc.

### `DocumentDetailsCommonModule`

```swift
public final class DocumentDetailsCommonModule: BaseModule {
    public init(/* injected view-state factory + view model */)
    public func viewController() -> UIViewController
}
```

The generic detail screen. Per-document-type detail flows (e.g. PID-specific extensions) compose around this rather than subclassing.

### `DocumentActionSheetModule`

```swift
public final class DocumentActionSheetModule: BaseModule {
    public init(/* injected actions */)
    public func viewController() -> UIViewController
}
```

The action sheet presented from a document card's overflow.

### `DocumentsCommonConfiguration`

```swift
public class DocumentsCommonConfiguration {
    public static let shared: DocumentsCommonConfiguration
    public func configure(/* images, flags */)
}
```

Same pattern as `WalletGalleryConfiguration` — host calls it once at launch to inject the image assets the package needs.

---

## 🌐 Dependencies

### `WalletDocumentsCommonTypes`

- `ReactiveKit` — observation in some view models.
- `lottie-spm` — animations in the design-system views.
- `DiiaMVPModule`, `DiiaCommonTypes`, `DiiaUIComponents`.

### `WalletDocumentsCore`

- `DiiaMVPModule`, `DiiaCommonTypes`, `DiiaCommonServices`, `DiiaUIComponents`.
- `lottie-spm`.
- `WalletDocumentsCommonTypes` (sibling target).

---

## 🗂 Module hierarchy

```text
              ┌────────────────────────────────┐
              │   DiiaGovStackWallet            │
              │   DocumentsCollection (host)    │
              │   Gallery / Details / Issuing   │
              └──────────────┬─────────────────┘
                             │ consume modules + types
                             ▼
              ┌────────────────────────────────┐
              │       WalletDocuments           │  ← you are here
              │   Core (modules, views)         │
              │   CommonTypes (protocols, types)│
              └────────────┬───────────────────┘
                           │ DocumentAttributesProtocol etc.
                           ▼
              WalletDomainModels (in WalletCore)
              (DocType conforms; pragmatic dep)
```

Layer: **domain + feature** — `WalletDomainModels` depends on `WalletDocumentsCommonTypes`; almost every feature SPM depends on `WalletDocumentsCore`.

Imported by: `WalletCore` (WalletDomainModels target → CommonTypes), `WalletGallery`, `WalletAddDocument`, `WalletIssuing`, `WalletSharing`, host app.

---

## ✅ Guidelines

- **Keep `WalletDocumentsCommonTypes` truly common.** No business logic, no host-specific assumptions. If a new type is only useful to one feature SPM, it stays in that feature's package — not here.
- **`WalletDomainModels` depends on CommonTypes — that's intentional.** `DocType`'s conformance to `DocumentAttributesProtocol` lives in the domain layer, which pulls `WalletDocumentsCommonTypes` into the closure. Don't try to "fix" it without rethinking the conformance.
- **Configuration injection is mandatory.** Both `DocumentsCommonConfiguration.shared.configure(...)` and the host-side image asset injection must run at launch before any UI in this package renders.
- **Detail-screen variation goes outside this package.** PID-specific or mDL-specific detail variants are handled by feature SPMs composing around `DocumentDetailsCommonModule`. Don't subclass the common detail VC inside this package.
- **No `EudiWalletKit` imports.** This package is purely UI + domain shape. EUDI-aware bridging belongs in `WalletEngine` / `WalletDomainModels`.

---

## 📖 See also

- [`WalletCore/README.md`](../WalletCore/README.md) — `DocType`, `Credential`, `WalletDomainModels`'s dependency on this package.
- [`WalletGallery/README.md`](../WalletGallery/README.md) — the gallery card factories that consume this package's chrome.
- [`WalletSharing/README.md`](../WalletSharing/README.md) — `DocumentsQRPlaceholderView` consumer.
