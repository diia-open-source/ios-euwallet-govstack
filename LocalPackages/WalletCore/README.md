# 🧠 WalletCore

> The architectural hub of the wallet. Three sibling targets in one package — pure domain models, ports + DI, and the EUDI engine implementation.

![Targets: 3](https://img.shields.io/badge/targets-3-blue)
![Layer: Core](https://img.shields.io/badge/layer-core-orange)
![Size: large](https://img.shields.io/badge/files-62-lightgrey)
![EUDI wall](https://img.shields.io/badge/EUDI--wall-enforced-red)

---

## 🎯 Purpose

`WalletCore` is the package every other local SPM ultimately depends on. It defines the wallet's domain language (what a credential, issuance offer, presentation request, or transaction log entry is), declares the **ports** that the host wires up with concrete implementations, and contains the **only** target in the entire repo allowed to import the EUDI reference iOS stack.

The package is intentionally split into three targets with strict dependency direction so feature modules can `import WalletDomainModels` for pure types, `import WalletCore` for protocol-driven access to engine functionality, and **never** see the SDK behind it.

---

## 🧱 Targets

```
WalletCore (package)
├── WalletDomainModels   pure value types, configuration, localization keys
├── WalletCore           protocol ports + DI registry + lifecycle coordinator
└── WalletEngine         the concrete EUDI implementation (SDK-coupled)
```

### 1. `WalletDomainModels`

The pure-data layer. Contains:

- Document models: `EudiPidDocumentModel`, `EudiMdlDocumentModel`, claim mappers, `DrivingPrivilege`, `DocItemValue`, `DocItemDisplayName`.
- Domain enums: `DocType`, `CredentialFormat`, `WalletDocumentType`, `DocumentCredentialStatus`.
- Issuance results: `Credential`, `IssuanceOffer`, `IssuanceOfferedDocument`, `IssuanceResult`, `WalletCredentialStoringResult`, `WalletCredentialStoringEvent`, `WalletCredentialIssuanceError`.
- Presentation models: `PresentationRequest`, `PresentationError`.
- Errors: `WalletDomainError` (so named to avoid colliding with EudiWalletKit's `WalletError`).
- Strings: `WalletStrings`, `WalletStringKey`, `WalletStringsProviding` — a regional-neutral string protocol so a different deployment can plug in its own copy.
- App utilities: `AppDateFormatter`, `AppDateStyle`, `AppDateSourceFormat`.
- Configuration: `WalletConfiguration` (loaded from `wallet-config.json` at the host).

**Dependencies:** `DiiaCommonTypes`, `DiiaDocumentsCommonTypes` — `DocType`'s conformance to `DocumentAttributesProtocol` pulls in the latter.

**Cannot import:** anything from `WalletCore`, `WalletEngine`, or the EUDI stack. This is the leaf of the package's internal dependency graph.

### 2. `WalletCore`

The protocol layer. This is what feature SPMs and the host depend on. Contains:

- **Ports** (`Sources/WalletCore/Ports/`):
  - `WalletKitProtocol` — the main facade. All credential operations (`loadDocuments`, `resolveCredentialOffer`, `issueDocument`, `requestDeferredIssuanceForAll`, `fetchDeferredDocuments`, etc.) go through this. The host wires in `WalletKitController` from `WalletEngine`.
  - `WalletErrorFormatting` — converts `PresentationError` into localized strings.
  - `WalletProximitySessionPort` / `WalletRemoteSessionPort` — port + delegate protocols for the two presentation flows. Each port is implemented by a session manager in `WalletEngine`.
  - `TransactionLogStorage` / `TransactionLogStore` — persistence ports for transaction history (in-memory store + on-disk storage).
- **Dependencies** (`Sources/WalletCore/Dependencies/WalletDependencies.swift`):
  - `WalletDependencies` — the central DI registry. Public `static func configure(...)` + `setX(_:)` accessors. Every protocol the wallet needs is exposed as a `public static var ... { get }` accessor. The host calls these at launch from `AppConfigurator`.
- **Lifecycle** (`Sources/WalletCore/Lifecycle/`):
  - `WalletLifecycleCoordinator` — orchestrates revocation polling, deferred-issuance polling, and alert flushing across login/foreground transitions.
  - `DocumentRevocationService` — periodic revocation checks against issuer revocation lists.
  - `PublicServiceFlowCoordinator` — top-level routing for service flows.
- **Utility** — date formatters, notification names, miscellaneous extensions.

**Dependencies:** `WalletDomainModels`, `DiiaCommonTypes`, `DiiaMVPModule`.

**Cannot import:** anything from `WalletEngine` or the EUDI stack.

### 3. `WalletEngine`

The implementation layer. The **only** target in the entire repo that may import:

- `EudiWalletKit`
- `OpenID4VCI` (transitively via EudiWalletKit)
- `OpenID4VP` (transitively)
- `WalletStorage` (the upstream eudi-lib-ios-wallet-storage credential store)
- `MdocSecurity18013`, `MdocDataModel18013`, `MdocDataTransfer18013`
- `StatiumSwift`
- `JOSESwift`

Contains:

- `WalletKitController` — the canonical `WalletKitProtocol` implementation. Wraps `EudiWallet` from `EudiWalletKit`.
- `WalletKitConfig` — the EUDI SDK configuration object (issuer registry, trust roots, key attestation provider, etc.).
- `WalletProximitySessionManager`, `WalletRemoteSessionManager` — concrete session managers for proximity (BLE / ISO 18013-5) and remote (HTTP / OID4VP) presentation.
- `WalletErrorFormatter` — concrete `WalletErrorFormatting` that loads issuer metadata for display-name lookups.
- `DefaultWalletAttestationsProvider` — HTTP client for the Wallet Provider's attestation endpoints (wallet-instance-attestation, wallet-unit-attestation). So named (`Default…`) to avoid colliding with EudiWalletKit's `WalletAttestationsProvider` protocol that it conforms to.
- `DefaultTransactionLogStorage` — disk-backed transaction log persistence.
- `Extensions/` — bridges between upstream EUDI types and our domain (`DocClaimsDecodable+Domain.swift`, `Document+Issuance.swift`, `WalletError+Domain.swift`).
- `Persistence/` — bridges for credential storage.

**Dependencies:** `WalletDomainModels`, `WalletCore`, plus the EUDI stack listed above.

---

## 🛡 The EUDI wall

The single most important architectural property of this package: **only `WalletEngine` may import EUDI symbols.** Every other target — every other package in the repo — talks to the engine through the protocol ports in `WalletCore/Sources/WalletCore/Ports/`.

This is enforced by the SPM dependency graph, not by convention. If you add `import EudiWalletKit` to (say) a file in `WalletGallery`, the build will fail with `Unable to resolve module dependency: 'EudiWalletKit'` because that package's `Package.swift` doesn't declare the dependency. Adding the dependency would require an explicit edit that any reviewer would catch — that's the canary.

The rationale is regional neutrality: if and when a non-EUDI engine implementation is needed (for a different national identity ecosystem), the swap happens in one target and one composition root file. No grep-and-replace across feature code.

---

## 🔌 The DI registry (`WalletDependencies`)

`WalletDependencies` is a `public enum` (no instances) that exposes static accessors for every wallet-scoped dependency. It backs onto a single private `Store` struct that is initialized by `configure(...)` and progressively populated by `setX(_:)` methods.

```swift
// At host launch, in AppConfigurator:
WalletDependencies.configure(
    transactionLogStore: TransactionLogStore(),
    transactionLogStorage: DefaultTransactionLogStorage(...),
    templatePresenter: HostTemplatePresenter(),
    documentsRefresher: AppWalletDocumentsRefresher(),
    remoteSharingPresenter: AppRemoteSharingPresenter(),
    authGate: AppWalletAuthGate(),
    onboardingLauncher: AppWalletOnboardingLauncher()
)

// Then wire concrete singletons:
WalletDependencies.setWalletController(WalletKitController.instance)
WalletDependencies.setWalletErrorFormatter(WalletErrorFormatter())
WalletDependencies.setProximitySessionFactory { WalletProximitySessionManager() }
WalletDependencies.setRemoteSessionFactory { WalletRemoteSessionManager() }

// Construct lifecycle services that need the dependencies above:
let lifecycle = WalletLifecycleCoordinator(...)
WalletDependencies.setWalletLifecycle(lifecycle)
```

### ⚠️ Bootstrap order trap

**Never** pass `EudiWalletKitController.instance` (or anything that reads other `WalletDependencies` slots) as a `configure(...)` argument. Swift evaluates function arguments eagerly, so the lazy singleton would touch other dependency slots before `configure(...)` had a chance to install the backing store. The crash is `WalletDependencies.transactionLogStore accessed before WalletDependencies.configure(...) was called`. Always use the separate `setX(_:)` methods *after* `configure(...)` returns.

Documented in memory: `feedback_wallet_deps_bootstrap_order`.

---

## 🔁 Lifecycle

`WalletLifecycleCoordinator` owns the cross-cutting wallet behaviours that need to react to login/logout/foreground transitions:

- **Revocation polling** — `DocumentRevocationService` checks issuer revocation lists on a fixed interval while the wallet is active.
- **Deferred-issuance polling** — `DeferredIssuancePolling` (interface in `WalletCore`, implementation in `WalletIssuing`) polls the OID4VCI deferred endpoint when at least one document has `WalletStorage.Document.isDeferred == true`.
- **Alert presentation** — outcomes are deferred via `alertHostProvider` and `flushPendingAlerts()` so screens that aren't currently visible don't try to present alerts at bad times.

```swift
walletLifecycle.startSession()   // call after successful login
walletLifecycle.endSession()     // call on logout
walletLifecycle.flushPendingAlerts()  // call when an alert-eligible host appears
```

---

## 📂 Package structure

```
WalletCore/
├── Package.swift
└── Sources/
    ├── WalletDomainModels/
    │   ├── Configuration/          # WalletConfiguration
    │   ├── Localization/           # WalletStrings, WalletStringKey, WalletStringsProviding
    │   ├── Models/                 # Documents, claims, presentation, issuance, errors
    │   └── Utility/                # AppDateFormatter
    ├── WalletCore/
    │   ├── Controller/             # PublicServiceFlowCoordinator
    │   ├── Dependencies/           # WalletDependencies (the DI registry)
    │   ├── Lifecycle/              # WalletLifecycleCoordinator, DocumentRevocationService
    │   ├── Ports/                  # WalletKitProtocol, error / session / log ports
    │   └── Utility/                # date / notification helpers
    └── WalletEngine/
        ├── Extensions/             # DocClaimsDecodable+Domain, Document+Issuance, WalletError+Domain
        ├── Kit/                    # WalletKitController, WalletKitConfig, attestation provider
        ├── Persistence/            # transaction log storage on disk
        └── Presentation/           # proximity & remote session managers, error formatter
```

---

## 🌐 Dependencies

```
WalletDomainModels  ◀────  DiiaCommonTypes
                    ◀────  DiiaDocumentsCommonTypes (from WalletDocuments)

WalletCore          ◀────  WalletDomainModels
                    ◀────  DiiaCommonTypes
                    ◀────  DiiaMVPModule

WalletEngine        ◀────  WalletDomainModels
                    ◀────  WalletCore
                    ◀────  EudiWalletKit  (and its transitive eudi-lib-* deps)
                    ◀────  JOSESwift
```

Declared in [`Package.swift`](Package.swift).

---

## 🗂 Module hierarchy

`WalletCore` sits at the bottom of the local-package dependency graph: every wallet feature module depends on it (specifically on the `WalletCore` and `WalletDomainModels` products). The `WalletEngine` product is consumed by **exactly one** file in the host app — [`AppConfigurator.swift`](../../DiiaGovStackWallet/AppConfigurator.swift) — which constructs the concrete singletons and hands them to `WalletDependencies`. After that, no other file touches `WalletEngine` directly.

Layer: **Foundation / Core** (Infrastructure tier).
Imports: only DiiaCommonTypes, DiiaMVPModule, EudiWalletKit (transitively for Engine).
Imported by: every feature SPM in the repo.

---

## ✅ Guidelines

- **Never import `EudiWalletKit` outside `WalletEngine`.** The `Package.swift` dependency graph enforces this — don't try to work around it.
- **Bridge types at the engine boundary.** When the engine returns an `EudiWalletKit.WalletError`, convert it to `WalletDomainError` (or to a more specific domain enum) before exposing it to a port consumer. See `Extensions/WalletError+Domain.swift`.
- **Configure once, set incrementally.** Use `WalletDependencies.configure(...)` for the value-typed dependencies known up-front, then `setX(_:)` for the singletons that need other dependencies to exist first.
- **Add new ports to `WalletCore/Ports/`, not `WalletEngine/`.** A port is a contract; the implementation lives in the engine. If you find yourself adding a protocol to the engine, you've probably written an implementation detail that should be inverted.
- **Domain types belong in `WalletDomainModels`.** If a new value type is referenced by a port, declare it in the domain target, not the core target. Keeps the dependency direction clean.
- **Don't import `WalletEngine` from feature modules.** The host is the only legitimate consumer. If a feature needs something from the engine, expose it through a `WalletDependencies` accessor (a protocol port) and call that.

---

## 📖 See also

- [`AppConfigurator.swift`](../../DiiaGovStackWallet/AppConfigurator.swift) — the one place that wires concrete engine instances into `WalletDependencies`.
