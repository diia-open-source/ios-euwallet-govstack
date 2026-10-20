# 📤 WalletSharing

> The wallet's presentation surface. OpenID4VP over HTTPS, ISO/IEC 18013-5 proximity over BLE, and QR-based local sharing — all in one package.

![Targets: 1](https://img.shields.io/badge/targets-1-blue)
![Layer: Feature](https://img.shields.io/badge/layer-feature-purple)
![Size: medium](https://img.shields.io/badge/files-11-lightgrey)
![Protocols: OID4VP, ISO 18013-5](https://img.shields.io/badge/protocols-OID4VP%20%2F%20ISO%2018013--5-blue)

---

## 🎯 Purpose

`WalletSharing` hosts every flow in which the wallet **presents** a credential to a verifier. Three distinct presentation modes share this package because they reuse the same disclosure-consent UI and the same `WalletDisclosureRequestAdapter` for translating verifier requests into domain language:

1. **Remote sharing** (`WalletRemoteSharingModule`) — OpenID4VP over HTTPS. The verifier hosts a `request_uri`; the wallet pulls it, validates the verifier's reader-auth chain against `verifierReaderTrustRoots`, shows the user what's being asked, and responds via direct-post or direct-post.jwt.
2. **Proximity sharing** (`WalletProximitySharingModule`) — ISO/IEC 18013-5 mDoc proximity over BLE. The wallet acts as the device, advertising an engagement QR (or NFC) that the verifier-side reader scans, then runs the device-retrieval transcript over BLE.
3. **QR sharing** (`DocumentsQRModule`) — a hybrid: show a static QR encoding the proximity engagement, watch for the BLE handshake, then fall through into the proximity flow. Used as the wallet's "show this to a verifier" entry point.

A small **adapter** layer (`WalletDisclosureRequestAdapter`, `WalletSharingDataHandler`) bridges the raw `PresentationRequest` from `WalletCore` ports into a disclosure consent screen and back into a sealed response.

---

## 🧱 Module structure

```
WalletSharing/
└── Sources/
    └── WalletSharing/
        ├── Common/
        │   └── Utilities/
        │       ├── WalletDisclosureRequestAdapter.swift  # PresentationRequest → disclosure rows
        │       └── WalletSharingDataHandler.swift        # Shared post-consent data handling
        ├── DocumentsQR/
        │   ├── DocumentsQRModule.swift                   # QR-engagement BaseModule
        │   ├── DocumentsQRPresenter.swift                # Presenter
        │   └── DocumentsQRViewController.swift           # Behaviour-heavy VC (QR + BLE engagement)
        ├── Views/
        │   └── QRCodeView.swift                          # CIFilter-backed QR view
        ├── WalletProximitySharing/
        │   ├── WalletProximitySharingModule.swift        # Proximity (BLE) module
        │   └── WalletProximitySharingPresenter.swift     # Owns WalletProximitySessionManaging
        └── WalletRemoteSharing/
            ├── WalletRemoteSharingFactory.swift          # Factory (WalletRemoteSharingPresenting)
            ├── WalletRemoteSharingModule.swift           # Remote (HTTPS) module
            └── WalletRemoteSharingPresenter.swift        # Owns WalletRemoteSessionManaging
```

Eleven files across four feature subfolders.

---

## 🔌 Public API

### `WalletRemoteSharingModule`

```swift
public final class WalletRemoteSharingModule: BaseModule {
    public init(link: String)
    public func viewController() -> UIViewController
}
```

Entry point for OID4VP remote presentation. Constructed by the host's `WalletSharingDeeplinkRouter` whenever an `openid4vp://`, `eudi-openid4vp://`, `mdoc-openid4vp://`, `mdl-openid4vp://`, `haip-vp://`, or `haip://` URL is opened. The `link` is the URL with its scheme stripped — the routing layer hands the bare query string to the presenter.

### `WalletRemoteSharingFactory`

```swift
public struct WalletRemoteSharingFactory: WalletRemoteSharingPresenting {
    public init()
    public func presentRemoteSharing(link: String, in view: BaseView)
}
```

Implements the `WalletRemoteSharingPresenting` port declared in `WalletCore`. Lets non-host code (e.g. `WalletIssuing` or `WalletGallery`) invoke remote sharing without depending on host routing.

### `WalletProximitySharingModule`

```swift
public final class WalletProximitySharingModule: BaseModule {
    public init(/* injected dependencies */)
    public func viewController() -> UIViewController
}
```

Entry point for ISO 18013-5 proximity. The presenter owns a `WalletProximitySessionManaging` (port) obtained from `WalletDependencies.makeProximitySession()`. Engagement is shown as a QR; once the verifier scans and connects over BLE, the session manager transitions through `engaged → requested → responded → completed`.

### `DocumentsQRModule`

```swift
public final class DocumentsQRModule: BaseModule {
    public init(/* injected dependencies */)
    public func viewController() -> UIViewController
}
```

The hybrid entry: display a static engagement QR, listen for verifier connection over BLE, and dispatch into the proximity flow on engagement.

### `QRCodeView`

```swift
public class QRCodeView: BaseCodeView {
    // Renders an arbitrary string as a QR via Core Image's CIQRCodeGenerator.
}
```

Reusable QR-rendering view. Used by `DocumentsQRViewController` and `WalletProximitySharingPresenter`.

### `WalletDisclosureRequestAdapter`

```swift
public struct WalletDisclosureRequestAdapter {
    public init()
    public func adapt(request: PresentationRequest) -> [DisclosureRow]
}
```

Translates a `PresentationRequest` (which describes which claims the verifier wants and from which documents) into a flat array of disclosure rows for the consent UI. Stateless.

---

## 🔄 Flow — remote (OID4VP)

```
deeplink: openid4vp://?request_uri=...
              │
              ▼
   WalletDeeplinkRouteBuilder → WalletSharingDeeplinkRouter
              │
              ▼
   WalletRemoteSharingModule(link:)
              │
              ▼  presenter pulls request_uri (via WalletKitProtocol)
   PresentationRequest
              │
              ▼  reader-auth chain validated against verifierReaderTrustRoots
              │  (trust gate: !=false → pass; lenient policy)
              │
              ▼  WalletDisclosureRequestAdapter.adapt(request:)
   [DisclosureRow] → consent screen
              │
              ▼  user approves
   WalletSharingDataHandler builds response (direct-post / direct-post.jwt)
              │
              ▼  WalletKitProtocol.submitPresentationResponse(...)
   transaction logged via WalletEngine → TransactionLogStore
              │
              ▼
   success screen → return
```

## 🔄 Flow — proximity (ISO 18013-5)

```
user: "Show to verifier" → DocumentsQRModule
              │
              ▼  presenter asks WalletDependencies.makeProximitySession()
   WalletProximitySessionManaging (impl in WalletEngine)
              │
              ▼  startQrEngagement() → engagement string
   QRCodeView renders engagement string
              │
              ▼  verifier-side reader scans → connects over BLE
   delegate.onRequest(PresentationRequest)
              │
              ▼  same disclosure / consent / response path as remote
              │
              ▼
   transaction logged → success
```

---

## 🌐 Dependencies

| Dependency | Why |
|---|---|
| `DiiaMVPModule` | MVP scaffolding. |
| `DiiaCommonTypes` | Shared types. |
| `DiiaCommonServices` | Common services (alerts, indicators). |
| `DiiaUIComponents` | Constructor UI + `BaseCodeView`. |
| `lottie-spm` | Engagement animation in proximity flow. |
| [`WalletAuthorization`](../WalletAuthorization/) (`WalletAuthorizationPinCode`) | Re-prompt PIN before high-value disclosures (per policy). |
| [`WalletDocuments`](../WalletDocuments/) (`WalletDocumentsCore`) | Document core types and view primitives. |
| [`WalletCore`](../WalletCore/) (`WalletCore` + `WalletDomainModels`) | `WalletKitProtocol`, `PresentationRequest`, `PresentationError`, `WalletProximitySession*`, `WalletRemoteSession*`, `WalletStringKey`. |

Both session managers are obtained via `WalletDependencies` and used as `WalletProximitySessionManaging` / `WalletRemoteSessionManaging` protocols.

---

## 🗂 Module hierarchy

```text
              ┌────────────────────────────────┐
              │   DiiaGovStackWallet host       │
              │   (deeplink router)             │
              └──────────────┬─────────────────┘
                             │
                             ▼
              ┌────────────────────────────────┐
              │       WalletSharing             │  ← you are here
              │ RemoteSharing  ProximitySharing │
              │ DocumentsQR  DisclosureAdapter  │
              └────────┬─────────┬─────────────┘
                       │         │
        ┌──────────────┘         └──────────────┐
        ▼                                        ▼
  WalletAuthorization                       WalletCore
  (PIN re-prompt for                         (WalletKitProtocol,
   high-value disclosures)                    PresentationRequest,
                                              session ports)
```

Layer: **feature** — depended on by the host (for deeplink routing) and by `WalletGallery`/`WalletIssuing` (for the "share now" entry).

---

## ✅ Guidelines

- **Trust gate is lenient by design.** The verifier reader-auth chain check is `!= false` — pass on indeterminate, block only on explicit failure. Don't flip to strict without policy approval.
- **Reader-auth nil is not the same as "valid".** The multiplatform verifier ships with `readerAuthCertificate = null`; under the lenient gate that passes, but it's a documented divergence.
- **Disclosure UI is the only place the user sees what's being shared.** Treat it as load-bearing. Don't let "convenience" abbreviations hide which claims are leaving the device.
- **PIN re-prompt belongs in the flow, not in the engine.** If a presentation needs PIN reconfirmation, the presenter pushes a `WalletAuthorizationPinCode` module; the engine call only happens after the PIN succeeds.
- **No `EudiWalletKit` imports.** Sessions, requests, errors — all go through ports from `WalletCore`.
- **Behaviour-heavy view controllers are an accepted exception.** `DocumentsQRViewController` subclasses `UIViewController` directly rather than using `ConstructorViewController` because BLE engagement state changes need bespoke transitions.

---

## 📖 See also

- [`WalletCore/README.md`](../WalletCore/README.md) — port protocols for the two session shapes.
