# 🔐 WalletAuthorization

> The wallet's authorization layer. Two targets: an authorization core (state machine + service) and a PIN-code / biometry feature module (`WalletAuthorizationPinCode`).

![Targets: 2](https://img.shields.io/badge/targets-2-blue)
![Layer: Feature + Service](https://img.shields.io/badge/layer-feature%20%2B%20service-orange)
![Size: large](https://img.shields.io/badge/files-37-lightgrey)

---

## 🎯 Purpose

`WalletAuthorization` owns everything that decides whether the user is currently authorized to use the wallet:

- **Authorization core** (`WalletAuthorization` target) — the `AuthorizationState` enum (`unauthorized` / `authorized` / `pinCodeRequested` / etc.), the `AuthorizationService` that runs the state machine, the `AuthorizationStorage` that persists relevant state, and the `UserAuthorizationFlow` enum that classifies the entry pathway (first launch, returning user, re-auth).
- **PIN-code + biometry** (`WalletAuthorizationPinCode` target) — the full set of PIN-management screens (create, enter, repeat, change), the biometry setup flow, the storage of PIN hashes (Keychain) and biometry-enabled flags (UserDefaults), and the biometry authentication service (Face ID / Touch ID prompts).

Two targets exist because consumers split cleanly: most features only need to *check* that the user is authorized (or trigger sign-out), which is the smaller `WalletAuthorization` surface. Only `WalletMenu` and `WalletSharing` (and the host's authorization shell) actually need the PIN screens — those consume `WalletAuthorizationPinCode`.

---

## 🧱 Targets

```
WalletAuthorization (package)
├── WalletAuthorization        state machine + service + storage; flow enum; no UI
└── WalletAuthorizationPinCode pin/biometry screens + view models + services
```

### `WalletAuthorization`

The auth core. Contains:

- **`AuthorizationContext`** + **`AuthorizationNetworkContext`** — context value types used by the service.
- **`AuthorizationService`** + **`AuthorizationServiceProtocol`** + **`AuthorizationServiceStateHandler`** — the state-machine implementation. Holds the current `AuthorizationState`, transitions it, notifies its single state handler.
- **`AuthorizationStorage`** + **`AuthorizationStorageImpl`** + **`AuthorizationStorageProtocol`** — the persistence layer for auth state and tokens. Routes through `WalletAppStorage.StoreHelper` under the hood.
- **`AuthorizationState`** — `userAuth`, `notAuthorized`.
- **`UserAuthorizationFlow`** — currently `login(completionHandler:)`; classifies the entry pathway and carries the completion callback.
- **`Logoutable`** — protocol implemented by `AuthorizationService` itself. `AuthorizationServiceProtocol: Logoutable` so any consumer holding the service can invoke `logout()` through the protocol.
- **Resources** — `R.Strings`, `R.Image` enums + the assets the target uses (close icon, loading bar, light background).

### `WalletAuthorizationPinCode`

The PIN/biometry feature surface. Contains:

- **`PinCodeViewModel`** + **`PinCodeManagerProtocol`** + **`PinCodeStorageProtocol`** + **`PinCodeStorageImpl`** — PIN handling primitives.
- **`PincodeView`** + the pincode `.xib` — the keypad view used across PIN screens.
- **`BiometryAuthService`** + **`BiometryAuthServiceProtocol`** + **`BiometryError`** + **`BiometryType`** — Face ID / Touch ID layer over `LAContext`.
- **`BiometryStorageImpl`** + **`BiometryStorageProtocol`** — biometry-enabled flag persistence.
- **Modules**:
  - `BiometrySetupModule` — first-time "Enable biometry" screen.
  - `CreatePinCodeModule` — set a new PIN.
  - `RepeatPinCodeModule` — confirm the new PIN.
  - `EnterPinCodeModule` / `BiometryEnterPinCodeModule` / `BiometryEnterPinCodeInContainerModule` — standard PIN entry, with optional biometry prompt; container variant for embedding inside a `BiometryEnterPinCodeContainerViewController`.
  - `ChangePincodeModule` — three-step change flow (enter old, enter new, repeat new).
- **Module contexts** — `EnterPinCodeModuleContext`, `ChangePincodeModuleContext` — context-typed entry points for each PIN flow.

Some modules subclass `UIViewController` directly (rather than using constructor presenters) because the PIN keypad UX is behaviour-heavy. The corresponding `.storyboard` files live next to the modules.

---

## 🧱 Module structure (abbreviated)

```
WalletAuthorization/
└── Sources/
    ├── WalletAuthorization/
    │   ├── AuthorizationContext.swift
    │   ├── Common/
    │   │   ├── AuthorizationStorage.swift
    │   │   ├── AuthorizationStorageImpl.swift
    │   │   ├── Models/
    │   │   │   ├── AuthorizationState.swift
    │   │   │   └── UserAuthorizationFlow.swift
    │   │   └── Services/AuthorizationService.swift
    │   └── Resources/
    │       ├── R+Strings.swift
    │       ├── R+images.swift
    │       └── Media.xcassets/
    └── WalletAuthorizationPinCode/
        ├── Common/
        │   ├── BiometryStorageImpl.swift
        │   ├── PinCodeStorageImpl.swift
        │   ├── PinCodeStorageProtocol.swift
        │   ├── PinCodeViewModel.swift
        │   ├── Services/
        │   │   ├── BiometryAuthService.swift
        │   │   └── BiometryAuthServiceProtocol.swift
        │   └── Views/
        │       ├── PincodeView.swift
        │       └── PincodeView.xib
        ├── Modules/
        │   ├── BiometrySetup/                     # Module + Presenter + VC + ViewModel
        │   ├── ChangePincode/                     # Module + Presenter + VC + ViewModel + storyboard
        │   ├── CreatePinCode/                     # Module + Presenter + VC + storyboard
        │   ├── EnterPinCode/                      # Standard + biometry variants + storyboard
        │   └── RepeatPinCode/                     # Module + Presenter + VC + storyboard
        ├── PinCodeModuleContexts.swift
        └── Resources/
            ├── R+Strings.swift
            ├── R+images.swift
            └── Media.xcassets/
```

37 files split across the two targets.

---

## 🔌 Public API highlights

### `AuthorizationService`

```swift
public final class AuthorizationService: AuthorizationServiceProtocol {
    public init(/* injected storage + context */)
    public var state: AuthorizationState { get }
    public func transition(to: AuthorizationState)
    public func add(handler: AuthorizationServiceStateHandler)
    public func logout()
    public func reauth()
    /* … */
}
```

The auth state machine. Consumers add a state handler to react to transitions; the host's `AuthorizationStateHandler` adapts these into route changes.

### `AuthorizationState`

```swift
public enum AuthorizationState {
    case userAuth
    case notAuthorized
}
```

Two cases. `userAuth` while a user session is active, `notAuthorized` at every other moment (first launch, post-logout, mid-PIN-entry before success).

### `UserAuthorizationFlow`

```swift
public enum UserAuthorizationFlow {
    case login(completionHandler: UserAuthorizationFlowCompletion)
}
```

Single case today, carrying the completion callback the host fires once login is finalised. The enum shape leaves room for additional entry pathways without breaking callers that switch exhaustively on it.

### `Logoutable`

```swift
public protocol Logoutable: AnyObject {
    func logout()
}
```

Implemented by `AuthorizationService` itself (`AuthorizationServiceProtocol: Logoutable`). Consumers call `logout()` through the protocol to clear auth state. Wallet-wide teardown (clearing credentials, the transaction log, the lifecycle services, etc.) is owned by the host's `AuthorizationStateHandler.onLogoutDidFinish()`, which the service invokes synchronously after flipping its own state.

### `CreatePinCodeModule`, `EnterPinCodeModule`, `ChangePincodeModule`, `BiometrySetupModule`

```swift
public final class CreatePinCodeModule: BaseModule { /* … */ }
public final class EnterPinCodeModule: BaseModule { /* … */ }
public final class BiometryEnterPinCodeModule: BaseModule { /* … */ }
public final class ChangePincodeModule: BaseModule { /* … */ }
public final class BiometrySetupModule: BaseModule { /* … */ }
```

Each module exposes its own context type (`EnterPinCodeModuleContext`, etc.) describing how to wire up the `onSuccess` / `onCancel` callbacks. The host or another feature constructs the module with a context value.

### `BiometryAuthService`

```swift
public final class BiometryAuthService: BiometryAuthServiceProtocol {
    public init()
    public func canEvaluatePolicy() -> Bool
    public func biometryType() -> BiometryType
    public func authenticate(reason: String, completion: @escaping (Result<Void, BiometryError>) -> Void)
}
```

Thin layer over `LAContext`. Used by `BiometryEnterPinCodeModule` and the settings biometry toggle.

---

## 🔄 Auth state flow

```
launch
  │
  ▼
AuthorizationService.state ── notAuthorized ─▶ host shows AuthorizationFlow
                                              │
                                              ▼
                                  first launch  ── CreatePinCodeModule → RepeatPinCodeModule
                                                      → BiometrySetupModule (optional)
                                                      → state = .userAuth → AuthorizationStateHandler.onLoginDidFinish()
                                  returning user ── EnterPinCodeModule (or BiometryEnterPinCodeModule)
                                                      → state = .userAuth → onLoginDidFinish()
                                  re-prompt      ── BiometryEnterPinCodeInContainerModule
                                                      (re-prompt inside the current screen's host)
                                                      → caller's completion callback fires
                                  logout         ── service.logout()
                                                      → hashedPincode = nil
                                                      → state = .notAuthorized
                                                      → AuthorizationStateHandler.onLogoutDidFinish()
                                                        (host runs wallet-wide teardown — see Data-Architecture-iOS.md §5.3 b)
                                  ▼
userAuth — wallet usable
```

---

## 🌐 Dependencies

### `WalletAuthorization` target

- `ReactiveKit` — observation in the service.
- `DiiaMVPModule`, `DiiaCommonTypes`, `DiiaCommonServices`.
- [`ios-core-uicomponents`](../ios-core-uicomponents/) — `DiiaUIComponents` for shared UI primitives in resources.
- [`WalletAppStorage`](../WalletAppStorage/) — storage backbone via `StoreHelper`.

### `WalletAuthorizationPinCode` target

- `DiiaMVPModule`, `DiiaCommonTypes`.
- [`ios-core-uicomponents`](../ios-core-uicomponents/) — `DiiaUIComponents`.
- [`WalletAppStorage`](../WalletAppStorage/) — for `StoringKey.authPincode` (Keychain) and `.biometryEnabled` (UserDefaults).
- `WalletAuthorization` (sibling target).

---

## 🗂 Module hierarchy

```text
              ┌────────────────────────────────┐
              │   DiiaGovStackWallet            │
              │   AuthorizationStateHandler     │  host adapts state → routing
              └──────────────┬─────────────────┘
                             │
                             ▼
              ┌────────────────────────────────┐
              │     WalletAuthorization         │  ← you are here
              │   AuthorizationService          │
              │   AuthorizationState  Flow      │
              └────────┬───────────────────────┘
                       │ used by
                       ▼
              ┌────────────────────────────────┐
              │   WalletAuthorizationPinCode    │
              │   PIN screens + biometry        │
              └────────┬───────────────────────┘
                       │
                       ▼
              WalletAppStorage
              (StoringKey.authPincode → Keychain,
               StoringKey.biometryEnabled → UserDefaults)
```

Layer: **feature + service** — the core target is depended on by anything that needs to know about auth state; the PinCode target is depended on by the host's auth shell and by `WalletMenu` (change-pin / biometry toggle entries) and `WalletSharing` (PIN re-prompt before high-value disclosures).

---

## ✅ Guidelines

- **Don't touch UserDefaults / Keychain directly.** All persistence in this package goes through `WalletAppStorage.StoreHelper`. If a new `StoringKey` is needed, add it to `WalletAppStorage` first.
- **PIN handling is hash-based.** `PinCodeStorageImpl` stores a hash in Keychain; the cleartext PIN never reaches disk. Don't add code that round-trips through the storage with cleartext.
- **Biometry is opt-in.** `BiometryAuthService.canEvaluatePolicy()` must succeed AND `StoringKey.biometryEnabled` must be true before the PIN flow offers a biometric option. Don't gate just on one.
- **State handlers are notified on the main thread.** Transitions trigger UI changes; consumers can assume `didChangeState` runs on `.main`.
- **`Logoutable` is the only sign-out hook.** When you add a new feature that caches user data, conform to `Logoutable` and register with `AuthorizationService` — don't duplicate sign-out cleanup logic in `AppRouter` or similar.
- **PIN screens use storyboards.** PIN keypad behaviour is heavy enough that the storyboard path is the right answer; forcing these screens into `ConstructorScreenPresenter` would add complexity for limited benefit.
- **No `EudiWalletKit` imports.** Auth doesn't talk to credentials.

---

## 📖 See also

- [`WalletAppStorage/README.md`](../WalletAppStorage/README.md) — `StoringKey` cases used by this package (`authPincode`, `biometryEnabled`, `lastPincodeDate`, etc.).
- [`DiiaGovStackWallet/Common/Authorization/`](../../DiiaGovStackWallet/Common/Authorization/) — host-side auth shell + `AuthorizationStateHandler` adapter.
- [`WalletMenu/README.md`](../WalletMenu/README.md) — settings entry points (change PIN, biometry toggle) that consume the PinCode target.
