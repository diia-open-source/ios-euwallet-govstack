# DiiaUIComponents

Basic UI components and primitives.

## Description

`DiiaUIComponents` is the design-system library: the constructor-driven UI engine plus the catalogue of reusable components used to compose screens.

It provides:

- **The constructor system** — `ConstructorViewController`, `ConstructorScreenPresenter`, `DSConstructorModel`, `DSComponent<Model>`, `DSViewBuilderProtocol`. Screens are composed from typed component descriptors and rendered without subclassing the view controller.
- **The design-system component library** — accordion, alert cards, buttons (primary / icon / icon group), carousels, checkboxes, calendars, cards, chips, list views, navigation bars, status lines, tabs, text fields, toggles, and more. Each component ships a `Builder`, a `Model`, and (for behaviour-heavy ones) a `View` with its `.xib`.
- **Reusable primitives** — `BaseCodeView`, `BaseModalView`, `BaseProgressView`, `BoxView`, `AnimationView` (Lottie), `ActionButton`, `ContentLoadingView`, `ChecklistView`, `ActionSheetOrgView`, `CheckmarkView`, `OpenSettingsAlertPresenter`.
- **MVP-friendly entrypoints** — `ConstructorModalView`, `ConstructorPaginationContainerCell`, `CustomActionSheetModule`, `CustomAlertModule`, `BaseNavigationController`.
- **The `Storyboarded` extension** — storyboard-loading helper for view controllers.
- **Resources** — design-system assets in `Resources/Assets.xcassets` and Lottie animations in `Resources/Animations`.

## Useful Links

|Topic|Link|Description|
|--|--|--|
|Ministry of Digital Transformation of Ukraine|https://thedigital.gov.ua/|The Official homepage of the Ministry of Digital Transformation of Ukraine|
|Diia App|https://diia.gov.ua/|The Official website for the Diia application|

## Getting Started

### Dependencies

* [DiiaCommonTypes](https://github.com/diia-open-source/ios-commontypes.git): Shared protocols and types.
* [DiiaMVPModule](https://github.com/diia-open-source/ios-mvpmodule.git): MVP primitives.
* [SwiftMessages](https://github.com/SwiftKickMobile/SwiftMessages) (`9.0.9`) — toast / inline message presentation.
* [Kingfisher](https://github.com/onevcat/Kingfisher) (`7.12.0+`) — remote image loading.
* [lottie-spm](https://github.com/airbnb/lottie-spm) (`4.6.0`) — Lottie animation rendering.

### Installing

This package lives in the wallet repository and is consumed locally via a path dependency:

```swift
.package(path: "../ios-core-uicomponents")
```

The upstream version is published at [diia-open-source/ios-uicomponents](https://github.com/diia-open-source/ios-uicomponents).

> **Folder name note.** In this repo the folder is `ios-core-uicomponents`, not `ios-uicomponents`. SwiftPM identifies a local package by its directory basename, and the wallet's sibling packages reference this one by the `ios-core-uicomponents` identity. The folder name must stay as-is so SwiftPM resolution succeeds — renaming to `DiiaUIComponents` or `ios-uicomponents` would break the override.

## Code Verification

### Swiftlint

This package follows the wallet project's SwiftLint configuration; the host enforces lint at build time.

## Modifications in this fork

In-tree fork of [`diia-open-source/ios-uicomponents`](https://github.com/diia-open-source/ios-uicomponents), maintained independently of upstream.

The wallet composes screens **locally** — driven by typed view-state factories on the client. The substantive additions on top of upstream:

### 1. `static var key` on `DSViewBuilderProtocol`

Each builder publishes a stable identifier so screens can be composed in code without round-tripping through JSON keys.

```swift
public protocol DSViewBuilderProtocol {
    static var key: String { get }
    // …
}

public final class DSStubMessageMlcViewBuilder: DSViewBuilderProtocol {
    public static let key = "stubMessageMlc"
    // …
}
```

### 2. `DSComponent<Model>` — typed component descriptor

`DSComponent<Model>` pairs a builder's static key with the typed model the builder expects, making screen composition type-safe at the call site.

```swift
public struct DSComponent<Model: Encodable> {
    public let key: String
    public init(key: String) { self.key = key }
}

// One typed descriptor per (builder, model) pair:
public extension DSComponent where Model == DSStubMessageMlc {
    static var stubMessageMlc: Self { .init(key: DSStubMessageMlcViewBuilder.key) }
}

public extension DSComponent where Model == DSTopGroupOrg {
    static var topGroupOrg: Self { .init(key: DSTopGroupViewBuilder.key) }
}
```

### 3. `AnyCodable.component(_:_:)` — type-checked composition

A small generic helper that turns a typed descriptor + matching model into the `AnyCodable` payload the constructor expects. The model type is compiler-enforced against the descriptor.

```swift
public extension AnyCodable {
    static func component<M: Encodable>(_ descriptor: DSComponent<M>, _ model: M) -> AnyCodable {
        .dictionary([descriptor.key: .fromEncodable(encodable: model)])
    }
}
```

### Putting it together

The three pieces above let a view-state factory compose a screen in plain Swift, with full type-checking, without any backend configuration:

```swift
let screen = DSConstructorModel(
    topGroup: [
        .component(.topGroupOrg, DSTopGroupOrg(
            titleGroupMlc: DSTopGroupMlc(heroText: "Add document", label: nil, hideBackButton: false)
        ))
    ],
    body: [
        .component(.sectionTitleAtm, DSTitleLabelMlc(label: "Choose a document type")),
        .component(.stubMessageMlc, DSStubMessageMlc(/* … */))
    ]
)
// → fed into ConstructorViewController; rendered without any subclassing.
```

For a fuller view-state-factory example see the wallet's top-level [`README.md`](../../README.md) ("Adding a new feature module").

### Other notable additions

- **Public initialisers** on `DSAccordion*Org*Model` types and similar models, added so wallet code can construct them in code (upstream relied on JSON decoding).
- **Folder kept at `ios-core-uicomponents`** rather than upstream's `ios-uicomponents` — see the *Folder name note* above for the SPM-identity reason.
- **`Diia` prefix preserved on public types.** This package keeps the `Diia` naming (`DiiaUIComponents`, `DSCommonCardView`, etc.) because the upstream-shaped product/target/folder identifiers are needed for the SPM override to work and because the sibling in-tree Diia packages hard-import `DiiaUIComponents` symbols.

Further wallet-side adjustments are tracked via the wallet repository's git history.

## How to contribute

This in-tree copy is maintained as part of the wallet project; contributions follow the wallet repository's contribution guidelines.

When considering a change inside this library:

1. **Can it be done at the call site?** If a feature needs to compose existing components differently, that composition belongs in the feature SPM, not here.
2. **Can it be done via configuration?** Many components take a builder/model/style triple — try expressing the change as new model state before adding a code path.
3. **Don't add wallet-domain types here.** Wallet-specific value types belong in `WalletDomainModels` or a feature SPM. This library is intentionally domain-agnostic.

## Licensing

Copyright (C) Diia and all other contributors.

Licensed under the **EUPL** (the "License"); you may not use this file except in compliance with the License. Re-use is permitted, although not encouraged, under the EUPL, with the exception of source files that contain a different license.

You may obtain a copy of the License in the [`LICENSE.md`](LICENSE.md) file and at [https://joinup.ec.europa.eu/collection/eupl/eupl-text-eupl-12](https://joinup.ec.europa.eu/collection/eupl/eupl-text-eupl-12).
