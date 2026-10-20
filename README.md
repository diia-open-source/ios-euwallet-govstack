# Wallet — iOS

> A regional-neutral digital identity wallet built on top of the EU Digital Identity reference stack.

![Swift 5.0](https://img.shields.io/badge/Swift-5.0-orange.svg)
![Xcode 15+](https://img.shields.io/badge/Xcode-15%2B-orange.svg?style=flat)
![iOS 16.2+](https://img.shields.io/badge/platform-iOS%2016.2%2B-orange.svg?style=flat)
![SPM](https://img.shields.io/badge/SwiftPM-enabled-orange.svg)
![EUDI](https://img.shields.io/badge/EUDI-OID4VCI%20%2F%20OID4VP%20%2F%20ISO%2018013--5-blue)
![Modular](https://img.shields.io/badge/Architecture-modular-blue)
![License: EUPL](https://img.shields.io/badge/License-EUPL--1.2-green)

---

## 📋 Table of contents

- [What this project is](#-what-this-project-is)
- [Architecture in one breath](#-architecture-in-one-breath)
- [App bootstrap flow](#-app-bootstrap-flow)
- [Project structure](#-project-structure)
- [Local SPMs at a glance](#-local-spms-at-a-glance)
- [Tech stack](#-tech-stack)
- [Getting started](#-getting-started)
- [Build configurations & schemes](#-build-configurations--schemes)
- [Configuration](#-configuration)
- [Deeplinks supported](#-deeplinks-supported)
- [Trust model in one paragraph](#-trust-model-in-one-paragraph)
- [Features (current capabilities)](#-features-current-capabilities)
- [Local SPM dependency graph](#-local-spm-dependency-graph)
- [Dependencies](#-dependencies)
- [Localization](#-localization)
- [Adding a new feature module](#-adding-a-new-feature-module)
- [Testing](#-testing)
- [Glossary](#-glossary)
- [Contributing](#-contributing)
- [License](#-license)

---

## 🎯 What this project is

A native iOS wallet application targeting the **EU Digital Identity (EUDI) Wallet** ecosystem. It implements:

- **Credential issuance** via **OpenID for Verifiable Credential Issuance** (OID4VCI), including deferred-issuance polling and transaction-code (Tx-code) flows.
- **Remote presentation** of credentials over HTTPS via **OpenID for Verifiable Presentations** (OID4VP), with support for HAIP, mDoc-OID4VP, and the SD-JWT VC payload format.
- **Proximity presentation** over BLE per **ISO/IEC 18013-5** (mDoc proximity, used for in-person verification of mobile Driver's Licence and Personal Identification Document).
- **Wallet-instance attestation** and key attestation against a Wallet Provider, per the EUDI Architecture Reference Framework.
- **Per-issuer signed-metadata trust** with verifier reader-auth chain validation at the proximity/remote boundary.

The wallet's four shared foundation packages — `DiiaMVPModule`, `DiiaCommonTypes`, `DiiaCommonServices`, and `DiiaUIComponents` — are forks of the open-source [Diia OSS](https://github.com/diia-open-source) Swift Packages (Ministry of Digital Transformation of Ukraine, EUPL-1.2). They live in-tree under [`LocalPackages/`](LocalPackages/) with wallet-specific modifications and are maintained independently of upstream. Each in-tree package's own `README.md` documents what differs.

The project follows a modular, region-neutral structure so the same shell can plug into different national identity ecosystems — EUDI today, with the architecture deliberately leaving room for other implementations behind the same dependency boundary. The host application is intentionally slim; nearly all features ship as local Swift Packages under [`LocalPackages/`](LocalPackages/).

---

## 🧭 Architecture in one breath

- **Modular by package.** Every feature is a local Swift Package. The host (`DiiaGovStackWallet/`) is a thin composition root — it wires concrete implementations into `WalletDependencies` at launch and routes deeplinks. Feature packages depend on each other only through declared protocol ports.
- **Single EUDI boundary.** The `WalletEngine` target inside [`WalletCore`](LocalPackages/WalletCore/) is the **only** module in the entire repo that may import `EudiWalletKit`, `OpenID4VCI`, `OpenID4VP`, `WalletStorage`, `MdocSecurity18013`, `MdocDataModel18013`, `MdocDataTransfer18013`, or `StatiumSwift`. Every other package consumes the engine through the `WalletKitProtocol` port and a handful of session-port protocols. The boundary is compiler-enforced — adding an `import EudiWalletKit` to any feature file fails to build with an `Unable to resolve module dependency` error because that package's `Package.swift` doesn't declare the dependency.
- **Composition root pattern.** The host's [`AppConfigurator.swift`](DiiaGovStackWallet/AppConfigurator.swift) is the single place where the engine is instantiated. From there it flows into `WalletDependencies.setX(_:)` accessors as opaque protocol instances. No feature module touches the engine type directly.
- **UI construction.** Feature screens use the constructor-driven UI from `DiiaUIComponents`. Each screen has three small files: a `*ViewStateFactory` (produces a `DSConstructorModel` from domain data), a `*Presenter : ConstructorScreenPresenter` (routes events via a per-module action enum), and a `*Module` (assembly). UIKit lives inside the constructor, not inside presenters.
- **MVP** scaffolding from `DiiaMVPModule` — `BaseModule`, `BaseView`, `BasePresenter`, `RouterProtocol`. No reactive frameworks in presenters by default; `ReactiveKit` is used inside a few specific managers.

---

## 🚦 App bootstrap flow

```
                       launch
                          │
                          ▼
              DiiaGovStackWalletApp / AppDelegate
                          │
                          ▼
                  AppConfigurator
                          │
   ┌──────────────────────┼──────────────────────┐
   │                      │                      │
   ▼                      ▼                      ▼
 WalletDependencies   WalletKitController   AppRouter
 .configure(...)      (engine singleton)    (top-level routing)
   │                      │                      │
   ▼                      ▼                      ▼
 set transactionLogStore, set walletController, set deeplink builders
 templatePresenter,   walletErrorFormatter,
 documentsRefresher,  proximitySessionFactory,
 authGate,            remoteSessionFactory
 onboardingLauncher
   │                      │
   └──────────┬───────────┘
              │
              ▼
   construct WalletLifecycleCoordinator
   (revocation polling + deferred-issuance polling + alert flushing)
              │
              ▼
   setWalletLifecycle(...)
              │
              ▼
   launch UI → SplashScreen → Authorization → MainTabBar
```

The bootstrap is **three-phase** and order-sensitive — see the WalletCore README's "Bootstrap order trap" section and `feedback_wallet_deps_bootstrap_order` in memory. Never pass `WalletKitController.instance` (or anything that reads other `WalletDependencies` slots) as an argument to `configure(...)`; use the dedicated `setX(_:)` methods afterward.

---

## 📦 Project structure

```
wallet/
├── LocalPackages/                     # All feature code, as local SPMs
│   ├── WalletCore/                    # 3-target architectural hub (Domain + Core + Engine)
│   ├── WalletDocuments/               # Document domain (CommonTypes + Core targets)
│   ├── WalletAuthorization/           # Auth + PinCode targets
│   ├── WalletAppStorage/              # GRDB-backed app persistence
│   ├── WalletGallery/                 # Document gallery (PID / mDL / deferred cards)
│   ├── WalletIssuing/                 # OID4VCI issuance flows
│   ├── WalletSharing/                 # OID4VP + ISO 18013-5 proximity sharing
│   ├── WalletAddDocument/             # Add-document selection flow
│   ├── WalletMenu/                    # Main menu
│   ├── WalletContextMenu/             # Context-menu primitives
│   ├── WalletTransaction/             # Transactions list & details
│   ├── WalletScannerBarcode/          # Barcode / QR scanner
│   ├── WalletSplashScreen/            # Splash screen
│   ├── ios-core-uicomponents/         # DiiaUIComponents — constructor UI / design system
│   ├── commontypes/                   # DiiaCommonTypes — shared protocols / value types
│   ├── core-common-services/          # DiiaCommonServices — alerts, error UI, helpers
│   └── ios-mvpmodule/                 # DiiaMVPModule — MVP scaffolding (folder names kept
│                                      # at upstream identity for SPM override)
├── DiiaGovStackWallet/                # Host iOS app (composition root + glue)
│   ├── AppConfigurator.swift          # Bootstrap: wires WalletDependencies
│   ├── AppDelegate.swift              # UIApplication entry, deeplink intake
│   ├── AppRouter.swift                # Top-level routing
│   ├── AppConstants.swift             # Host-scoped constants
│   ├── Info.plist                     # Bundle metadata + URL schemes
│   ├── Base.lproj/                    # LaunchScreen
│   ├── Common/
│   │   ├── Authorization/             # Host-side wiring for WalletAuthorization (state handler, contexts)
│   │   ├── DeepLinks/                 # DeepLinkManager + route builders
│   │   ├── Documents/                 # DocumentsCollectionContextImpl (host-routing layer)
│   │   ├── Extensions/                # UIApplication+visibleViewController
│   │   ├── Services/                  # AppMenuFlowProvider, WalletQRScannerHelper, ServicesProvider, …
│   │   └── Wallet/
│   │       ├── Certificates/          # IACA root certificates (.der)
│   │       └── Configuration/         # wallet-config.json + AppWalletAuthGate / OnboardingLauncher / DocumentsRefresher
│   ├── MainTabBar/                    # Tab-bar shell (top-level navigation)
│   └── Resources/
│       ├── R+String.swift             # R.Strings enum (all localized keys)
│       ├── R+images.swift             # R.Image enum
│       ├── Strings/                   # en.lproj/Localizable.strings, uk.lproj.disabled/…
│       └── Assets/                    # Host-app asset catalog
├── DiiaGovStackWallet.xcodeproj/      # Xcode project (PBXFileSystemSynchronizedRootGroup)
├── CodeGeneration/                    # Xcode file templates (.xctemplate)
├── README.md
├── CONTRIBUTING.md
├── LICENSE.md
├── .swiftlint.yml
├── .gitignore
└── .gitlab-ci.yml
```

The Xcode project uses `PBXFileSystemSynchronizedRootGroup` for both `DiiaGovStackWallet/` and `LocalPackages/`, so adding a new file or package picks up automatically — no `project.pbxproj` edits needed for typical additions.

---

## 📚 Local SPMs at a glance

| Package | Targets | Role |
|---|---|---|
| [`WalletCore`](LocalPackages/WalletCore/) | `WalletDomainModels`, `WalletCore`, `WalletEngine` | Domain types + DI registry + lifecycle + the EUDI engine. The architectural hub. |
| [`WalletDocuments`](LocalPackages/WalletDocuments/) | `WalletDocumentsCommonTypes`, `WalletDocumentsCore` | Document domain layer (`DocumentAttributesProtocol`, `DocumentStackIconAppearance`, document collection presentation primitives). |
| [`WalletAuthorization`](LocalPackages/WalletAuthorization/) | `WalletAuthorization`, `WalletAuthorizationPinCode` | Authorization protocol + PIN-code enrollment/entry/change/biometry. |
| [`WalletAppStorage`](LocalPackages/WalletAppStorage/) | `WalletAppStorage` | GRDB-backed local persistence + UserDefaults-backed `StoreHelper` typed key/value store. |
| [`WalletGallery`](LocalPackages/WalletGallery/) | `WalletGallery` | Document gallery — PID, mDL, deferred document cards; view-state factories per doc type. |
| [`WalletIssuing`](LocalPackages/WalletIssuing/) | `WalletIssuing` | OID4VCI flows: credential offer resolution, document issuance, Tx-code input, wallet onboarding, deferred-issuance polling. |
| [`WalletSharing`](LocalPackages/WalletSharing/) | `WalletSharing` | OID4VP remote sharing (HTTPS), ISO 18013-5 proximity sharing (BLE), QR-based local sharing, disclosure-request handling. |
| [`WalletAddDocument`](LocalPackages/WalletAddDocument/) | `WalletAddDocument` | Add-document selection flow (browse available docs, kick off issuance). |
| [`WalletMenu`](LocalPackages/WalletMenu/) | `WalletMenu` | Main menu and settings screens. |
| [`WalletContextMenu`](LocalPackages/WalletContextMenu/) | `WalletContextMenu` | Shared context-menu component used by Gallery and Issuing. |
| [`WalletTransaction`](LocalPackages/WalletTransaction/) | `WalletTransaction` | Transactions list and details (presentation history). |
| [`WalletScannerBarcode`](LocalPackages/WalletScannerBarcode/) | `WalletScannerBarcode` | Barcode / QR scanner module. |
| [`WalletSplashScreen`](LocalPackages/WalletSplashScreen/) | `WalletSplashScreen` | First-frame splash. |
| [`ios-core-uicomponents`](LocalPackages/ios-core-uicomponents/) | `DiiaUIComponents` | Constructor-driven UI system and design-system component library. Forked from upstream Diia OSS; folder name kept at upstream SPM identity. |
| [`commontypes`](LocalPackages/commontypes/) | `DiiaCommonTypes` | Shared protocols and value types. Forked from upstream Diia OSS; folder name kept at upstream SPM identity. |
| [`core-common-services`](LocalPackages/core-common-services/) | `DiiaCommonServices` | Common services (alerts, error UI, biometry helpers). Forked from upstream Diia OSS; folder name kept at upstream SPM identity. |
| [`ios-mvpmodule`](LocalPackages/ios-mvpmodule/) | `DiiaMVPModule` | MVP scaffolding (Module / View / Presenter / Router). Forked from upstream Diia OSS; folder name kept at upstream SPM identity. |

Each package has its own `README.md` with detailed structure, public API surface, and dependencies.

---

## 🧰 Tech stack

### Language & runtime
- **Swift 5.0** language mode, compiled with Xcode 15+.
- **iOS 16.2** minimum deployment target (16.0 for SPMs).
- **iPhone-only** (`TARGETED_DEVICE_FAMILY = 1`).

### UI
- **UIKit** (not SwiftUI). All view controllers and views are UIKit-based.
- **`DiiaUIComponents`** — the constructor-driven UI system. Each domain model is rendered into a `DSConstructorModel`, the screen is composed of `DSComponent<Model>` descriptors, and the view controller is `ConstructorViewController` (no subclassing required for most screens).
- **`DiiaMVPModule`** — MVP scaffolding (Module / View / Presenter / Router).

### EUDI plumbing
- **`EudiWalletKit`** v0.30.1 — the upstream EU Digital Identity wallet kit.
- **`OpenID4VCI`** — credential issuance protocol.
- **`OpenID4VP`** — verifiable-presentation protocol.
- **`MdocDataModel18013`, `MdocSecurity18013`, `MdocDataTransfer18013`** — ISO/IEC 18013-5/-7 mDoc plumbing.
- **`WalletStorage`** — upstream credential storage from `eudi-lib-ios-wallet-storage`.
- **`StatiumSwift`** — status list (revocation) handling.
- **`eudi-lib-sdjwt-swift`** — SD-JWT VC payload handling.
- **`JOSESwift`** — JWT/JWK manipulation for wallet attestations.

### Persistence
- **GRDB** — SQLite ORM, used inside `WalletAppStorage` for transaction logs and document order.
- **UserDefaults** — typed via `StoringKey` in `WalletAppStorage.StoreHelper`.
- **Keychain** — auth PIN storage and biometric state (via `WalletAuthorization`).

### Networking
- The wallet has no app-level HTTP layer of its own — credential issuance/presentation traffic is handled inside the EUDI stack (`OpenID4VCI` / `OpenID4VP`).
- **`Alamofire`** — used by `DiiaCommonServices.ReachabilityHelper` for network-reachability monitoring.
- **`ReactiveKit`** — reactive signals used in a handful of places (authorization context, certain managers).

### Other
- **`Lottie`** v4.6.0 — animations.
- **`Kingfisher`** — remote image loading (icons in `DiiaUIComponents`).
- **`SwiftMessages`** — toast / inline message presentation.

---

## 🚀 Getting started

### Prerequisites

| Requirement | Version |
|---|---|
| Xcode | 15+ (16 recommended — `PBXFileSystemSynchronizedRootGroup` displays cleaner) |
| iOS deployment target (app) | 16.2 |
| iOS deployment target (SPMs) | 16.0 (15.0 for `DiiaUIComponents` and `WalletDocuments`) |
| Swift language mode | 5.0 |
| macOS | Whichever matches your Xcode 15/16 install |

For device builds you'll need Apple Developer signing. Retarget signing for your team in the Signing & Capabilities tab.

### Clone & open

```bash
git clone <this-repo>.git
cd wallet
open DiiaGovStackWallet.xcodeproj
```

Let Xcode resolve the SPM graph. First-time resolution takes a couple of minutes — it resolves ~17 local packages (13 Wallet feature modules + 4 in-tree Diia OSS) and ~20 remote dependencies including the EUDI stack.

Pick the `DiiaGovStackWallet` scheme and run on a simulator or device.

### Command-line build

The project's SwiftLint build phase respects `SKIP_SWIFTLINT=1` — set it to bypass linting and surface only Swift compile errors:

```bash
xcodebuild -project DiiaGovStackWallet.xcodeproj \
  -scheme DiiaGovStackWallet \
  -destination 'generic/platform=iOS Simulator' \
  -configuration Debug \
  -skipPackagePluginValidation \
  -skipMacroValidation \
  ENABLE_USER_SCRIPT_SANDBOXING=NO \
  SKIP_SWIFTLINT=1 \
  build 2>&1 | tee /tmp/wallet-build.log
```

Why each flag matters:

| Flag | Purpose |
|---|---|
| `SKIP_SWIFTLINT=1` | Project-defined env var; bypasses the SwiftLint Run Script build phase. |
| `ENABLE_USER_SCRIPT_SANDBOXING=NO` | Xcode's stricter sandbox blocks legitimate script reads. |
| `-skipPackagePluginValidation` | Removes the interactive plugin-trust prompt. |
| `-skipMacroValidation` | Removes the interactive macro-trust prompt. |

To find real Swift compile errors after the build:

```bash
grep -nE 'error:' /tmp/wallet-build.log
```

### Resolve the package graph alone (no build)

Handy when you've added/renamed a local package and want to verify SPM still accepts the layout before committing to a full compile:

```bash
xcodebuild -project DiiaGovStackWallet.xcodeproj \
  -scheme DiiaGovStackWallet \
  -resolvePackageDependencies \
  -skipPackagePluginValidation -skipMacroValidation
```

### Troubleshooting

- **`Unable to resolve module dependency: 'EudiWalletKit'` in a feature file** — this is the EUDI-wall canary firing. Some feature file is trying to `import EudiWalletKit` directly. Find it, replace the import with whatever protocol port lives in `WalletCore/Ports/`, route through `WalletDependencies`.
- **Build fails with "unable to override package … doesn't match override's identity (directory name)"** — a local package's folder name doesn't line up with an upstream URL identity it's trying to override. See the explicit case in `LocalPackages/ios-core-uicomponents/` — the folder name is intentionally upstream-identity-shaped.
- **Storyboard runtime crash with SIGABRT during `instantiateViewController(withIdentifier:)`** — a storyboard's `customModule="…"` attribute encodes a module name that doesn't match the current target name. Grep `customModule="OldName"` in `.storyboard` / `.xib` files and fix.
- **`WalletDependencies.X accessed before WalletDependencies.configure(...) was called`** — bootstrap order trap. Don't pass dependency-consuming arguments to `configure(...)`; use `setX(_:)` after `configure(...)` returns. See `feedback_wallet_deps_bootstrap_order` in memory.

---

## ⚙️ Build configurations & schemes

The project ships one scheme (`DiiaGovStackWallet`) and two configurations (Debug, Release):

| Field | Debug | Release |
|---|---|---|
| `PRODUCT_BUNDLE_IDENTIFIER` | `ua.wallet.dev.test` | `ua.govstack.digitalwallet.app.dev` |
| `INFOPLIST_KEY_CFBundleDisplayName` | `Diia GovStack Wallet` | `Diia GovStack Wallet` |
| `MARKETING_VERSION` | `0.0.1` | `0.0.1` |
| `CURRENT_PROJECT_VERSION` | `1` | `1` |
| `IPHONEOS_DEPLOYMENT_TARGET` | `16.0` | `16.0` |
| `SWIFT_VERSION` | `5.0` | `5.0` |
| `TARGETED_DEVICE_FAMILY` | `1` (iPhone) | `1` (iPhone) |

Both Debug and Release point at the same Info.plist (`DiiaGovStackWallet/Info.plist`) and the same display name. The split is essentially the bundle ID + provisioning profile.

---

## 🔧 Configuration

Runtime wallet configuration lives in [`DiiaGovStackWallet/Common/Wallet/Configuration/wallet-config.json`](DiiaGovStackWallet/Common/Wallet/Configuration/wallet-config.json) and is loaded by `WalletConfiguration` (in `WalletDomainModels`) at launch. The schema:

```jsonc
{
  "issuers": [
    {
      "host": "issuer.example.com",        // Hostname (no scheme, no port) used by OID4VCI.
      "displayPriority": 0,                 // Ordering hint for issuer pickers; lower = earlier.
      "metadataTrustRoots": ["root_basename"]
                                            // List of certificate basenames (matching
                                            // .der files in Common/Wallet/Certificates/)
                                            // whose chains may sign this issuer's
                                            // openid-credential-issuer metadata JWT.
    }
    /* … one entry per supported issuer */
  ],
  "verifierReaderTrustRoots": [
    "iaca_root_basename_1",
    "iaca_root_basename_2"
    /* IACA root certificate basenames whose chains may sign verifier
       reader-auth certificates during OID4VP and ISO 18013-5 proximity
       presentations. */
  ]
}
```

The wallet keeps the per-issuer trust roots scoped so a self-signed certificate accepted for one issuer (e.g. a demo issuer) isn't silently accepted for another (e.g. a production EUDI reference issuer).

Certificate `.der` files referenced by basename in the config live in [`DiiaGovStackWallet/Common/Wallet/Certificates/`](DiiaGovStackWallet/Common/Wallet/Certificates/). They're loaded via `Bundle.main.url(forResource:withExtension:)` — iOS flattens app-bundle resource paths at build time, so the subfolder layout is invisible to the resolver. See [`WalletKitConfig.swift`](LocalPackages/WalletCore/Sources/WalletEngine/Kit/WalletKitConfig.swift) for the load logic.

---

## 🔗 Deeplinks supported

The host registers the URL schemes below in [`Info.plist`](DiiaGovStackWallet/Info.plist) and routes them via [`WalletDeeplinkRouteBuilder.swift`](DiiaGovStackWallet/Common/DeepLinks/Routers/WalletDeeplinkRouteBuilder.swift). Two flows, two router types:

### Issuance (OID4VCI)

| Scheme | Example | Routed to |
|---|---|---|
| `openid-credential-offer` | `openid-credential-offer://?credential_offer_uri=...` | `DocumentIssuanceModule` |
| `haip-vci` | `haip-vci://...` | `DocumentIssuanceModule` |

### Presentation (OID4VP / ISO 18013-5 over HAIP)

| Scheme | Example | Routed to |
|---|---|---|
| `openid4vp` | `openid4vp://?request_uri=...` | `WalletRemoteSharingModule` |
| `eudi-openid4vp` | `eudi-openid4vp://...` | `WalletRemoteSharingModule` |
| `mdoc-openid4vp` | `mdoc-openid4vp://...` | `WalletRemoteSharingModule` |
| `mdl-openid4vp` | `mdl-openid4vp://...` | `WalletRemoteSharingModule` |
| `haip-vp` | `haip-vp://...` | `WalletRemoteSharingModule` |
| `haip` | `haip://...` | `WalletRemoteSharingModule` |

A `RouterProtocol` consumer (e.g. a QR scanner result handler) calls `WalletDeeplinkRouteBuilder.create(with: urlString)` and dispatches to the returned router. `needAuth()` is false because both flows handle their own user-presence requirements internally.

---

## 🛡 Trust model in one paragraph

The wallet runs a **lenient trust gate**: presentation is blocked only when verifier reader-auth chain validation **explicitly fails** (the gate evaluates `!= false`, treating "indeterminate" as pass-through). This is a deliberate policy decision — flipping it to strict requires explicit policy approval. Per-issuer signed-metadata roots are configured in `wallet-config.json` (above) so trust is scoped, not global.

---

## 🧱 Features (current capabilities)

| Feature | Owned by | Status |
|---|---|---|
| PIN-code enrollment + entry + change | `WalletAuthorization` (`WalletAuthorizationPinCode`) | Stable |
| Biometric unlock (Face ID / Touch ID) | `WalletAuthorization` | Stable |
| Document gallery with reorderable cards | `WalletGallery` | Stable |
| PID (Personal Identification Document) | `WalletGallery` + EUDI ARF claim mapping | Stable |
| mDL (mobile Driver's Licence) | `WalletGallery` + ISO 18013-5 claim mapping | Stable |
| Deferred-document card | `WalletGallery` + `WalletIssuing` deferred coordinator | Stable |
| OID4VCI issuance | `WalletIssuing` + `DocumentIssuance` flow | Stable |
| OID4VCI Tx-code input | `WalletIssuing` + `TxCodeInput` flow | Stable |
| Wallet onboarding (first launch) | `WalletIssuing` + host-side launcher | Stable |
| OID4VP remote presentation | `WalletSharing` + `WalletRemoteSharing` flow | Stable |
| ISO 18013-5 proximity presentation | `WalletSharing` + `WalletProximitySharing` flow | Stable |
| QR-based local sharing | `WalletSharing` + `DocumentsQR` flow | Stable |
| Transactions list & details | `WalletTransaction` | Stable |
| Add-document selection | `WalletAddDocument` | Stable |
| Main menu | `WalletMenu` | Stable |
| QR / barcode scanner | `WalletScannerBarcode` | Stable |
| Splash screen | `WalletSplashScreen` | Stable |

---

## 🗺 Local SPM dependency graph

```text
                    ┌──────────────────────────────────────┐
                    │         DiiaGovStackWallet           │
                    │       (host: composition + glue)     │
                    └────────────┬─────────────┬───────────┘
                                 │             │
              ┌──────────────────┘             └──────────────────┐
              │                                                    │
   ┌──────────▼──────────┐                              ┌─────────▼─────────┐
   │ Wallet feature SPMs │   ─────────────────────▶     │     WalletCore     │
   │ (Gallery, Issuing,  │      (depend via ports)      │ Domain + Core +    │
   │  Sharing, AddDoc,   │                              │ Engine             │
   │  Menu, Transaction, │                              │                    │
   │  Splash, Scanner,   │                              │ ◀── only target    │
   │  ContextMenu)       │                              │     allowed to     │
   └──────────┬──────────┘                              │     import         │
              │                                          │     EudiWalletKit  │
              ▼                                          └───────┬───────────┘
   ┌──────────────────────┐                                      │
   │   WalletDocuments    │     ◀────────────────────────────────┘
   │  WalletAppStorage    │            (depended on by Engine)
   │  WalletAuthorization │
   └──────────────────────┘

   The upstream Diia OSS packages — DiiaUIComponents, DiiaCommonTypes,
   DiiaCommonServices, DiiaMVPModule — are in-tree (folder names kept
   at upstream SPM identity) and consumed across the UI and feature layers.
```

---

## 🌐 Dependencies

### Local SPMs

All under [`LocalPackages/`](LocalPackages/). See the [table above](#-local-spms-at-a-glance) or each package's own `README.md`.

### Diia OSS (in-tree)

All in-tree under [`LocalPackages/`](LocalPackages/), with folder names kept at upstream SPM identity so they resolve as local overrides of the upstream `*.git` packages:

- `DiiaMVPModule` — Model-View-Presenter primitives → [`LocalPackages/ios-mvpmodule/`](LocalPackages/ios-mvpmodule/).
- `DiiaCommonTypes` — shared protocols and value types → [`LocalPackages/commontypes/`](LocalPackages/commontypes/).
- `DiiaCommonServices` — common services (alerts, error UI, biometry helpers) → [`LocalPackages/core-common-services/`](LocalPackages/core-common-services/).
- `DiiaUIComponents` — constructor-driven UI system → [`LocalPackages/ios-core-uicomponents/`](LocalPackages/ios-core-uicomponents/).

The upstream `DiiaNetwork` (`ios-network`) package is not used — nothing in the wallet performs a real network call through it.

### EUDI reference iOS stack

- `EudiWalletKit` (`0.30.1`) — the main EUDI SDK.
- `OpenID4VCI` — credential issuance.
- `OpenID4VP` — verifiable presentation.
- `MdocDataModel18013`, `MdocSecurity18013`, `MdocDataTransfer18013` — mDoc ISO 18013-5/-7.
- `WalletStorage` — credential persistence.
- `StatiumSwift` — status-list / revocation.
- `eudi-lib-sdjwt-swift` — SD-JWT VC.

### 3rd-party

- `JOSESwift`, `Alamofire`, `ReactiveKit`, `GRDB`, `Lottie`, `SwiftMessages`, `Kingfisher`, `CryptoSwift`, `SwiftCBOR`, `swift-crypto`, `swift-asn1`, `swift-certificates`, `swift-collections`, `swift-syntax`, `swift-log`, `secp256k1.swift`, `Zlib`, `jose-swift`, `Copyable`.

---

## 🌍 Localization

The host app's translatable strings live in [`DiiaGovStackWallet/Resources/Strings/`](DiiaGovStackWallet/Resources/Strings/):

- `en.lproj/Localizable.strings` — **shipped** English locale.
- `uk.lproj.disabled/` — checked-in Ukrainian translation, **disabled at build time** by the `.disabled` folder suffix. Kept in sync because it's likely to be re-enabled.

Workflow for adding a new string:

1. Add the case to `R.Strings` in [`R+String.swift`](DiiaGovStackWallet/Resources/R+String.swift).
2. Add the `"key" = "Value";` line to **both** `en.lproj/Localizable.strings` **and** `uk.lproj.disabled/Localizable.strings.disabled`.
3. Reference via `R.Strings.<key>.localized()` or, if the SPM provides its own enum, the SPM-local `WalletStringKey` extension.

Per-SPM strings live inside each package's `Sources/.../Localization/` and use their own `*StringsProviding` protocol bridge so a future regional deployment can swap the string source without renaming call sites.

---

## 🧩 Adding a new feature module

Recipe for a typical feature screen:

1. **Pick the right package**. New issuance behaviour → `WalletIssuing`. New presentation flow → `WalletSharing`. New document type → coordinate with `WalletGallery` + `WalletDocuments` + `WalletCore`'s domain models. Standalone screen → consider whether it deserves its own SPM (typical threshold: 3+ files of cohesive responsibility).

2. **Create the three files** for the screen:
   - `<Name>ViewStateFactory.swift` — `public struct <Name>ViewStateFactory: <Name>ViewStateFactoryProtocol` returning a `DSConstructorModel` for the given domain model.
   - `<Name>Presenter.swift` — `final class <Name>Presenter: ConstructorScreenPresenter`. Owns the action enum `<Name>Action: String` and routes events.
   - `<Name>Module.swift` — `public final class <Name>Module: BaseModule` that wires the factory + presenter + `ConstructorViewController`.

   A typical view-state factory composes the screen from typed `DSComponent` descriptors — the `.component(.<key>, <model>)` calls are compile-time-checked so a `(.stubMessageMlc, DSCardMlcV2Model(...))` mismatch fails to build:

   ```swift
   public struct AddDocumentViewStateFactory: AddDocumentViewStateFactoryProtocol {
       public init() {}

       public func make(state: AddDocumentContentState) -> DSConstructorModel {
           DSConstructorModel(
               topGroup: [
                   .component(.topGroupOrg, DSTopGroupOrg(
                       titleGroupMlc: DSTopGroupMlc(
                           heroText: WalletStringKey.addDocumentTitle.localized(),
                           label: nil,
                           hideBackButton: false
                       )
                   ))
               ],
               body: [
                   .component(.sectionTitleAtm, DSTitleLabelMlc(label: WalletStringKey.chooseFromList.localized())),
                   // … one .component(.<descriptor>, <model>) per visible component
               ]
           )
       }
   }
   ```

   The typed descriptors (`DSComponent.topGroupOrg`, `.sectionTitleAtm`, `.stubMessageMlc`, …) are defined in `DSComponent.swift` inside `DiiaUIComponents`; each binds a constructor key to its expected model type. See the `DiiaUIComponents` [README](LocalPackages/ios-core-uicomponents/README.md) for the underlying convention.

3. **Wire any new ports through `WalletCore`**. If the screen needs to talk to the engine, add a protocol port to `WalletCore/Sources/WalletCore/Ports/` and expose it via `WalletDependencies`. Implement it in `WalletEngine` (the only target allowed to know about EUDI specifics).

4. **Add the Package.swift dependency** if the new screen lives in a feature SPM that didn't previously depend on, say, `WalletDocuments`. Run `xcodebuild -resolvePackageDependencies` to validate the graph before building.

5. **For deeplinks**: register the URL scheme in `Info.plist`, add the scheme to `WalletDeeplinkRouteBuilder.sharingSchemes` or `issuanceSchemes`, and return the new router from `create(with:)`.

6. **For storyboards/xibs** (rare; only for behaviour-heavy screens): set `customModule="<TargetName>"` and `customModuleProvider="target"` on every `<placeholder customClass="…">` element. Mismatched `customModule` is the most common cause of `SIGABRT` on `instantiateViewController(withIdentifier:)`.

7. **Strings**: add to both `Localizable.strings` files + the `R.Strings` enum.

Canonical reference module: [`LocalPackages/WalletMenu/Sources/WalletMenu/Main/`](LocalPackages/WalletMenu/Sources/WalletMenu/Main/) — three small files. Copy the pattern.

---

## 🧪 Testing

Feature verification is currently manual via the host scheme. The intended unit-test layout when tests are added:

- Per-SPM unit tests as `Tests/<TargetName>Tests/` inside each package.
- Use the package's port protocols to mock the engine — never `import EudiWalletKit` in a test target outside `WalletEngineTests`.
- Snapshot tests for the `DSConstructorModel` outputs to catch view-state regressions.

---

## 📒 Glossary

| Term | Meaning |
|---|---|
| **EUDI** | EU Digital Identity. The regulatory + technical framework targeted by this wallet. |
| **EUDI ARF** | Architecture Reference Framework — the EUDI normative spec for wallet behaviour. |
| **PID** | Personal Identification Document. The primary EUDI identity credential. |
| **mDL** | Mobile Driver's Licence (per ISO/IEC 18013-5). The first non-PID credential the wallet supports. |
| **mDoc** | A document encoded per ISO/IEC 18013-5 (mDoc = the data structure; the protocol is the rest of 18013-5). |
| **OID4VCI** | OpenID for Verifiable Credential Issuance — the protocol the wallet uses to *receive* credentials from an issuer. |
| **OID4VP** | OpenID for Verifiable Presentations — the protocol the wallet uses to *present* credentials to a verifier. |
| **SD-JWT VC** | Selective-Disclosure JWT Verifiable Credential — one of the two payload formats supported (mDoc CBOR is the other). |
| **IACA** | Issuer Authority Certificate Authority — the root certificate authority that signs verifier reader-auth certificates. |
| **HAIP** | High-Assurance Interoperability Profile — an OpenID/EUDI interop profile. |
| **DPoP** | Demonstration of Proof-of-Possession — token-binding mechanism used in the OID4VCI auth flow. |
| **PAR** | Pushed Authorization Request — OAuth 2.0 extension used in the OID4VCI flow. |
| **Tx-code** | Transaction code — a short numeric code an issuer can require the user to type before issuance, for out-of-band confirmation. |
| **Reader auth** | The verifier's authentication of itself to the wallet at the start of a presentation, via an x.509 certificate chain rooted in an IACA. |
| **Wallet attestation** | A JWT signed by the Wallet Provider asserting that this wallet instance is trustworthy; required for OID4VCI. |
| **Composition root** | The single place in the app where concrete dependencies are wired together. Here: [`AppConfigurator.swift`](DiiaGovStackWallet/AppConfigurator.swift). |
| **WalletDependencies** | The host-wide DI registry exposed by `WalletCore`. Initialised in three phases at launch. |
| **WalletEngine** | The only target in the repo allowed to import EUDI SDK symbols. The implementation boundary. |
| **WalletKitProtocol** | The main port through which feature modules talk to the engine. Implemented by `WalletKitController` in `WalletEngine`. |

---

## 🤝 Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

When working in this repo, the following conventions are load-bearing:

- **Don't import `EudiWalletKit` outside `WalletEngine`** — the build will reject it.
- **Never amend or force-push** without explicit ask.
- **Branches** are switched in SourceTree by the maintainer; don't auto-create branches.

---

## 📄 License

EUPL-1.2 — see [LICENSE.md](LICENSE.md). Re-use is permitted under EUPL terms.

The four in-tree Diia OSS foundation packages under [`LocalPackages/`](LocalPackages/) retain their original EUPL-1.2 license and Diia copyright; each has its own `LICENSE` file.
