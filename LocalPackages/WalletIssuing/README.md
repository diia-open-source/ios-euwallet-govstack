# 📥 WalletIssuing

> The wallet's OID4VCI surface. Document issuance, transaction-code input, deferred-issuance polling, and first-launch wallet onboarding.

![Targets: 1](https://img.shields.io/badge/targets-1-blue)
![Layer: Feature](https://img.shields.io/badge/layer-feature-purple)
![Size: medium](https://img.shields.io/badge/files-10-lightgrey)
![Protocol: OID4VCI](https://img.shields.io/badge/protocol-OID4VCI-blue)

---

## 🎯 Purpose

`WalletIssuing` is the user-facing surface for **OpenID for Verifiable Credential Issuance** (OID4VCI). It hosts three related flows:

1. **Wallet onboarding** (`WalletOnboardingModule`) — first-launch flow that explains what the wallet does, provisions the device's wallet-instance attestation against the Wallet Provider, and prompts the user to add their first document.
2. **Document issuance** (`DocumentIssuanceModule`) — the main OID4VCI exchange. Resolves the credential offer (from a deeplink URL or QR scan), shows the issuer description and the consent screen, runs the auth flow, hands the issuance request off to `WalletEngine`, and surfaces success/failure.
3. **Transaction-code input** (`DocumentTxCodeInputModule`) — modal sub-flow within issuance for issuers that require the user to type a Tx-code received out-of-band before issuance can complete.

A fourth piece is the **deferred-issuance coordinator** (`DeferredIssuanceCoordinator`) — a background service that polls the OID4VCI deferred-credential endpoint while the wallet has any documents in `WalletStorage.Document.isDeferred == true`. It implements the `DeferredIssuancePolling` port declared by `WalletCore` and is owned by `WalletLifecycleCoordinator` once started.

---

## 🧱 Module structure

```
WalletIssuing/
└── Sources/
    └── WalletIssuing/
        ├── DeferredIssuance/
        │   └── DeferredIssuanceCoordinator.swift          # Background poller (DeferredIssuancePolling)
        ├── DocumentIssuance/
        │   ├── DocumentIssuanceModule.swift               # BaseModule
        │   ├── DocumentIssuancePresenter.swift            # ConstructorScreenPresenter
        │   ├── DocumentIssuanceViewStateFactory.swift     # DSConstructorModel
        │   └── IssuanceDescriptionCardDescriptor.swift    # Custom card component
        ├── TxCodeInput/
        │   ├── DocumentTxCodeInputModule.swift            # Tx-code modal BaseModule
        │   ├── DocumentTxCodeInputPresenter.swift         # Tx-code presenter
        │   └── DocumentTxCodeInputView.swift              # Behaviour-heavy view (subclasses UIViewController)
        └── WalletOnboarding/
            ├── WalletOnboardingModule.swift               # First-launch BaseModule
            └── WalletOnboardingPresenter.swift            # First-launch presenter
```

Ten files in four feature subfolders.

---

## 🔌 Public API

### `DocumentIssuanceModule`

```swift
public final class DocumentIssuanceModule: BaseModule {
    public init(
        offerUri: String,
        viewStateFactory: DocumentIssuanceViewStateFactoryProtocol
    )
    public func viewController() -> UIViewController
}
```

The main issuance entry point. Constructed by the host's `WalletIssuanceDeeplinkRouter` whenever an `openid-credential-offer://` or `haip-vci://` URL is opened. The presenter:

1. Parses the offer URI via `WalletKitProtocol.resolveCredentialOffer(...)`.
2. Renders the issuer description + consent screen using `IssuanceDescriptionCardBuilder` and the constructor model.
3. On consent, runs the OID4VCI authorisation code flow (PAR + auth + token), prompting for Tx-code if the issuer requires it.
4. Calls `WalletKitProtocol.issueDocument(...)` and surfaces a success or failure state.

### `WalletOnboardingModule`

```swift
public final class WalletOnboardingModule: BaseModule {
    public init(/* injected dependencies + onFinish callback */)
    public func viewController() -> UIViewController
}
```

First-launch flow. Three intro slides + a call-to-action that provisions the wallet attestation and lets the user add their first document (typically a PID).

### `DocumentIssuanceViewStateFactoryProtocol`

```swift
public protocol DocumentIssuanceViewStateFactoryProtocol {
    func make(offer: IssuanceOffer, state: DocumentIssuanceScreenState) -> DSConstructorModel
}

public struct DocumentIssuanceViewStateFactory: DocumentIssuanceViewStateFactoryProtocol {
    public init()
}
```

The pure factory layer between domain (offer + state) and the constructor model.

### `IssuanceDescriptionCardBuilder`, `IssuanceDescriptionCardModel`

A custom DS component that renders the per-issuer description card (issuer name, logo, supported credential types). The model/builder pair plugs into the standard `DSComponent` descriptor pipeline.

### `DeferredIssuanceCoordinator` (`DeferredIssuancePolling`)

```swift
public final class DeferredIssuanceCoordinator: DeferredIssuancePolling {
    public init(walletController: WalletKitProtocol = WalletDependencies.walletController)
    public func start(presentAlert: @escaping (AlertTemplate) -> Void)
    public func stop()
    public func kick()
}
```

The polling service. Owned by `WalletLifecycleCoordinator` (started after login, stopped on logout). Polls the OID4VCI deferred endpoint on a fixed interval while the wallet has at least one deferred document and the app is foregrounded. `kick()` lets the issuance flow nudge it after a fresh deferred issuance, since `start()` itself only auto-triggers on foreground transitions.

---

## 🔄 OID4VCI flow (issuance)

```
deeplink: openid-credential-offer://?credential_offer_uri=...
              │
              ▼
   WalletDeeplinkRouteBuilder → WalletIssuanceDeeplinkRouter
              │
              ▼
   DocumentIssuanceModule(offerUri:)
              │
              ▼  presenter.viewDidLoad
   WalletKitProtocol.resolveCredentialOffer(uri:)
              │
              ▼  (returns IssuanceOffer)
   render description + consent (via DocumentIssuanceViewStateFactory)
              │
              ▼  user taps "Add document"
   WalletKitProtocol.startAuthorization(offer:)
              │
              │── PAR + AS authorize ───────────────────┐
              │                                          │
              │  (issuer requires Tx-code?)              │
              ▼                                          ▼
   DocumentTxCodeInputModule presented modally           skip
              │                                          │
              ▼  user types code                         │
              └──────────────┬───────────────────────────┘
                             │
                             ▼
   WalletKitProtocol.issueDocument(authorization:)
              │
              ▼  → success                              ▼  → deferred
   credential persisted via WalletEngine             DeferredIssuanceCoordinator.kick()
   transaction logged                                 (poll on foreground until issued/failed)
              │
              ▼
   success screen → return to gallery
```

---

## 🌐 Dependencies

| Dependency | Why |
|---|---|
| `DiiaMVPModule` | MVP scaffolding. |
| `DiiaCommonTypes` | Shared types (`AlertTemplate`, `Callback`). |
| `DiiaCommonServices` | Loading / alert presentation. |
| `DiiaUIComponents` | Constructor UI. |
| [`WalletContextMenu`](../WalletContextMenu/) | "Support" entry in the issuance screen's navigation overflow. |
| [`WalletDocuments`](../WalletDocuments/) (`WalletDocumentsCore`) | Document core types and view primitives. |
| [`WalletCore`](../WalletCore/) (`WalletCore` + `WalletDomainModels`) | `WalletKitProtocol`, `IssuanceOffer`, `Credential`, `WalletDependencies`, `DeferredIssuancePolling`, `WalletStringKey`. |

`WalletKitProtocol` mediates everything that touches the SDK.

---

## 🗂 Module hierarchy

```text
              ┌────────────────────────────────┐
              │   DiiaGovStackWallet host       │
              │   (deeplink router + lifecycle) │
              └──────────────┬─────────────────┘
                             │
                             ▼
              ┌────────────────────────────────┐
              │       WalletIssuing             │  ← you are here
              │ DocumentIssuance / TxCodeInput  │
              │ WalletOnboarding                │
              │ DeferredIssuanceCoordinator     │
              └────────┬───────────────────────┘
                       │
        ┌──────────────┼──────────────────┐
        ▼              ▼                  ▼
  WalletContextMenu   WalletDocuments   WalletCore
  (support menu)      (Core types)      (WalletKitProtocol via DI,
                                         IssuanceOffer, Credential)
```

Layer: **feature** — depended on by the host (for deeplink routing and onboarding launch), depends on Core + Documents + ContextMenu.

---

## ✅ Guidelines

- **No `EudiWalletKit` imports.** All credential operations go through `WalletKitProtocol`. If something seems impossible through the port, extend the port; don't bypass it.
- **Tx-code is a separate module.** Resist the temptation to inline Tx-code prompting inside `DocumentIssuancePresenter`. The modular `DocumentTxCodeInputModule` keeps the flow legible and the screen testable.
- **Deferred issuance is not optional.** Some issuers always defer (manual review). `DeferredIssuanceCoordinator` must run for the duration of a wallet session; if `WalletLifecycleCoordinator` doesn't start it, deferred docs silently never resolve.
- **Onboarding state lives in `WalletAppStorage`.** Use `StoringKey.hasAppBeenLaunchedBefore` to decide whether to show onboarding. Don't invent a new key for "have we onboarded".
- **Comment your timeouts.** `DeferredIssuanceCoordinator.Constants.settleDelaySeconds` is tuned to 15s for QA and intended to drop to ~5s before shipping. Mark such constants with `// TODO: tune before ship`.
- **Custom DS components stay local until reused.** `IssuanceDescriptionCardBuilder` lives in this package; only promote to `DiiaUIComponents` if a second feature wants it.

---

## 📖 See also

- [`WalletCore/README.md`](../WalletCore/README.md) — `WalletKitProtocol`, `IssuanceOffer`, `DeferredIssuancePolling`, `WalletLifecycleCoordinator`.
- [`WalletDocuments/README.md`](../WalletDocuments/README.md) — the document core types the issuance flow produces.
