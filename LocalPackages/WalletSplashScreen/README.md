# 🌅 WalletSplashScreen

> First-frame splash module shown while the host bootstraps. A canonical single-target presenter package.

![Targets: 1](https://img.shields.io/badge/targets-1-blue)
![Layer: Feature](https://img.shields.io/badge/layer-feature-purple)
![Size: small](https://img.shields.io/badge/files-4-lightgrey)
![Pattern: constructor](https://img.shields.io/badge/pattern-constructor-blue)

---

## 🎯 Purpose

`WalletSplashScreen` renders the initial loading frame the user sees immediately after launch, while the host's bootstrap completes (resource loading, `WalletDependencies` configuration, authorization state check). It is intentionally minimal: a background image (or a fallback colour), an optional title from `WalletStringKey.splashScreenTitle`, and an `onFinish` callback the host fires when it's ready to hand control to the authorization or main-tab screen.

The package is a textbook **constructor-driven** module: a `ViewStateFactory` produces a `DSConstructorModel`, a `Presenter` (subclassing `ConstructorScreenPresenter`) routes events through a per-screen action enum, and the `Module` ties them together — three small files plus a list of constructor-component descriptors.

---

## 🧱 Module structure

```
WalletSplashScreen/
└── Sources/
    └── WalletSplashScreen/
        ├── SplashScreenModule.swift            # Assembly: factory + presenter + view controller
        ├── SplashScreenPresenter.swift         # Subclass of ConstructorScreenPresenter
        ├── SplashScreenViewStateFactory.swift  # Builds the DSConstructorModel
        └── SplashConstructorComponents.swift   # Descriptor extensions for component keys
```

Four files. Same four-file shape as every other feature screen in the project.

---

## 🔌 Public API

The package exposes one entry point — the module class. Everything else is package-internal.

```swift
public final class SplashScreenModule: BaseModule {

    public init(
        backgroundImage: UIImage?,
        onFinish: @escaping Callback
    )

    // BaseModule conformance:
    public func viewController() -> UIViewController
}
```

### Construction

```swift
let splash = SplashScreenModule(
    backgroundImage: UIImage(named: "splash_background"),  // optional
    onFinish: { [weak self] in
        self?.appRouter.transitionToAuthorization()
    }
)
appRouter.show(module: splash)
```

The presenter calls `onFinish` once the splash's display window elapses (or immediately, if the host hands it a synchronous "ready" signal). The host is responsible for keeping the splash on screen until any pre-auth work it cares about has completed.

---

## 🧩 The pattern in one screen

This is the smallest legible example of the project's UI architecture. Worth reading in full as the canonical reference.

### 1. `SplashScreenViewStateFactory`

```swift
public protocol SplashScreenViewStateFactoryProtocol {
    func make(title: String?) -> DSConstructorModel
}

public struct SplashScreenViewStateFactory: SplashScreenViewStateFactoryProtocol {
    public init() {}
    public func make(title: String?) -> DSConstructorModel {
        // Build the DSConstructorModel from primitive `DSComponent` descriptors
        // declared in SplashConstructorComponents.swift.
    }
}
```

The factory is **pure**: it takes domain inputs and returns a `DSConstructorModel`. No `UIKit` imports beyond what `DiiaUIComponents` already carries. No side effects.

### 2. `SplashScreenPresenter`

```swift
final class SplashScreenPresenter: ConstructorScreenPresenter {
    unowned var view: ConstructorScreenViewProtocol

    private let backgroundImage: UIImage?
    private let onFinish: Callback
    private let viewStateFactory: SplashScreenViewStateFactoryProtocol

    func configureView()
    // … handles the screen lifecycle, calls onFinish at the right moment.
}
```

Subclasses `ConstructorScreenPresenter`. Holds the inputs, holds the factory, calls `view.setupBackground(...)` and `view.configure(model:)` with the factory's output. No direct `UIView` manipulation beyond the `.image(_:)` / `.color(_:)` background setup.

The presenter still does `import UIKit` — but only because `setupBackground` takes a `UIImage`. The "no UIKit in presenters" rule is aspirational across the project; this presenter does the minimum.

### 3. `SplashScreenModule`

```swift
public final class SplashScreenModule: BaseModule {
    public init(backgroundImage: UIImage?, onFinish: @escaping Callback) {
        // wires factory + presenter + ConstructorViewController
    }
}
```

The composition root. No business logic — just wiring.

### 4. `SplashConstructorComponents`

A `DSComponent` descriptor extension file. One descriptor per UI primitive the splash uses. Following the project-wide convention, descriptors live next to the screen that owns them and source their keys from the SPM builder's `static var key`.

---

## 🌐 Dependencies

| Dependency | Why |
|---|---|
| `DiiaMVPModule` | `BaseModule`, `BasePresenter`, `Callback`. |
| `DiiaCommonTypes` | Shared protocols. |
| `DiiaUIComponents` | `ConstructorScreenPresenter`, `ConstructorViewController`, `DSConstructorModel`, `DSComponent`. |
| [`WalletCore`](../WalletCore/) | `WalletStringKey.splashScreenTitle`, `WalletStringsProviding` for localized text. |

No third-party deps. No persistence. No networking. No EUDI symbols.

---

## 🗂 Module hierarchy

```text
                  ┌───────────────────────┐
                  │   DiiaGovStackWallet   │  host app
                  │   AppRouter            │
                  └──────────┬────────────┘
                             │ constructs once, on launch
                             ▼
              ┌──────────────────────────────┐
              │      WalletSplashScreen       │  ← you are here
              │  SplashScreenModule           │
              └────────────┬─────────────────┘
                           │ depends on:
            ┌──────────────┼──────────────┐
            ▼              ▼              ▼
        WalletCore   DiiaUIComponents  DiiaMVPModule
        (strings)    (constructor)     (BaseModule)
```

Layer: **leaf feature** — depended on by the host, depends on the core + the UI library.

Imports `WalletCore` (for `WalletStringKey`), `DiiaMVPModule`, `DiiaCommonTypes`, `DiiaUIComponents`. Imported by the host only.

---

## ✅ Guidelines

- **Keep this screen boring.** It's the user's first impression and the host's bootstrap window — any added complexity here adds latency to launch. Resist the urge to put progress indicators, animations, or "tip of the day" content inside the splash. The host can present those after `onFinish`.
- **Don't add asynchronous work in the presenter.** The splash is a passive display; whoever constructed it (the host) is responsible for the work that delays `onFinish`. Keep the presenter synchronous so the splash never gets stuck waiting on something it shouldn't be doing.
- **Three files plus one descriptor file is the right shape** for a feature screen of this complexity.
- **Background image is optional.** When `backgroundImage` is `nil`, the presenter falls back to a flat white background. Don't add image-loading logic inside the presenter — pass a pre-loaded `UIImage` or none.
- **No `EudiWalletKit` imports.** Splash is pure presentation; nothing here should need the engine or any domain protocol beyond what `WalletStringKey` provides.

---

## 📖 See also

- [`WalletCore/README.md`](../WalletCore/README.md) for `WalletStringKey` and `WalletStringsProviding`.
- `DiiaUIComponents.ConstructorScreenPresenter` for the base presenter class.
