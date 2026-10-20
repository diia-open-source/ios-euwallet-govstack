# 💾 WalletAppStorage

> The wallet's app-level persistence layer. Typed UserDefaults / Keychain key-value store plus a GRDB-backed transaction log.

![Targets: 1](https://img.shields.io/badge/targets-1-blue)
![Layer: Infrastructure](https://img.shields.io/badge/layer-infrastructure-orange)
![Size: medium](https://img.shields.io/badge/files-5-lightgrey)
![Storage: UserDefaults + Keychain + GRDB](https://img.shields.io/badge/storage-UserDefaults%20%2B%20Keychain%20%2B%20GRDB-blue)

---

## 🎯 Purpose

`WalletAppStorage` is the persistence layer for **non-credential** wallet state — everything that isn't a verifiable credential. Credentials themselves live in the upstream `eudi-lib-ios-wallet-storage` (which `WalletEngine` accesses via `WalletStorage`); this package is for app-domain data like pin-code state, biometric enrolment flags, document order preferences, and the verifiable-presentation transaction log.

There are two distinct subsystems inside, with different storage backends:

1. **`StoreHelper`** — a typed key/value store routed across UserDefaults and Keychain based on the key's sensitivity. Encodable values only.
2. **`TransactionLogController`** — a GRDB / SQLite-backed log of presentation events (who asked for what, when, what was disclosed), wired into `WalletCore.WalletDependencies` so any feature module can read from it without knowing about the database.

The two are unrelated in purpose but ship in the same package because they're both "host-instance state" rather than credentials.

The package is named `WalletAppStorage` (not `WalletStorage`) specifically to avoid a hard collision with the EUDI stack's `WalletStorage` target. See the README's "Naming" section below.

---

## 🧱 Module structure

```
WalletAppStorage/
└── Sources/
    └── WalletAppStorage/
        ├── StoreHelper.swift                               # Typed K/V store + StoringKey enum
        └── TransactionLog/
            ├── TransactionLogConfig.swift                  # Config struct (db backend, file name)
            ├── TransactionLogController.swift              # Composition root for the log subsystem
            ├── GRDBTransactionLogStore.swift               # Concrete TransactionLogStore on GRDB
            └── GRDBTransactionLog.swift                    # GRDB row + record type
```

Five files. Two clearly delineated subsystems.

---

## 🔌 Public API

### `StoringKey`

The canonical list of every app-level setting the wallet tracks.

```swift
public enum StoringKey: String, CaseIterable {
    case hasAppBeenLaunchedBefore   = "kUDHasAppBeenLaunchedBefore"
    case lastPincodeDate            = "kUDLastPincodeDate"
    case incorrectPincodeCount      = "kUDIncorrectPincodeCount"
    case incorrectPincodeChangeCount = "kUDIncorrectPincodeChangeCount"
    case authPincode                = "kKCAuthorizationPincode"      // ← Keychain
    case biometryEnabled            = "kUDBiometryEnabled"
    case docsOrder                  = "kUDDocsOrder"
    case docsStackOrder             = "kUDDocsStackOrder"
    case docsFlatOrder              = "kUDDocsFlatOrder"
    case pidDocument                = "kDSPIDDocument"
    case mdlDocument                = "kDSmDLDocument"
}
```

The `k`/`kUD`/`kKC` prefix convention encodes both the storage class (KeyChain vs UserDefaults) and the original "kUserDefaults" Cocoa idiom. Don't rely on parsing these prefixes — the actual routing is decided by `StoreHelper.StorageType(storingKey:)`, which today routes `.authPincode` to Keychain and everything else to UserDefaults.

Add a new case here when introducing new persisted state. Adjust `StorageType(storingKey:)` if it should go to Keychain.

### `StoreHelperProtocol`

```swift
public protocol StoreHelperProtocol {
    func save<T>(_ value: T, type: T.Type, forKey key: StoringKey) where T: Codable
    func getValue<T>(forKey key: StoringKey) -> T? where T: Codable
    func removeValue(forKey key: StoringKey)
    func clearAllData()
}
```

The interface every consumer codes against. The injectable shape lets tests swap in a stub without touching real UserDefaults or Keychain.

### `StoreHelper`

```swift
public final class StoreHelper: StoreHelperProtocol {
    public static let instance = StoreHelper()
    private init() {}
    // …conformance below…
}
```

Singleton concrete implementation. The composition root passes `StoreHelper.instance` to anything that needs a `StoreHelperProtocol`. The instance encodes values via a `JSONEncoder` (wrapped in an internal `StoreContainer<T>` to keep round-tripping of optional/nullable values consistent) and routes reads/writes to the storage backend chosen by `StorageType`.

`clearAllData()` removes every `StoringKey` from both backends — used by full logout.

### `TransactionLogConfig`

```swift
public struct TransactionLogConfig {
    public enum Database {
        case grdb
    }
    public let database: Database
    public let databaseDirectoryName: String
    public let databaseFileName: String
}
```

A small value type the host passes when constructing the controller. The `database` enum exists as a seam for future backends; only `.grdb` is implemented today.

### `TransactionLogController`

```swift
public final class TransactionLogController {
    public let transactionLogStore: TransactionLogStore
    public var transactionLogStorage: TransactionLogStorage {
        WalletDependencies.transactionLogStorage
    }
    public init(config: TransactionLogConfig)
}
```

Owns the GRDB queue and exposes a `TransactionLogStore` (the port declared by `WalletCore`) that the engine can write to. The `transactionLogStorage` pass-through is a convenience accessor that exposes `WalletDependencies.transactionLogStorage` from this controller, so host call sites can read the storage through whichever entry point fits their pattern.

Creation pattern (in the host):

```swift
let config = TransactionLogConfig(
    database: .grdb,
    databaseDirectoryName: "Wallet",
    databaseFileName: "transactions.db"
)
let controller = TransactionLogController(config: config)
WalletDependencies.configure(
    transactionLogStore: controller.transactionLogStore,
    transactionLogStorage: DefaultTransactionLogStorage(/* from WalletEngine */),
    // …
)
```

The controller initialiser creates the directory under `Application Support/<databaseDirectoryName>/` and opens (or creates) the SQLite file there.

---

## 🪪 Naming and quirks

### Why `WalletAppStorage` and not `WalletStorage`?

`WalletStorage` is also the name of a target in the upstream `eudi-lib-ios-wallet-storage` package, which `EudiWalletKit` depends on transitively and which therefore appears in our resolved package graph. SPM identifies overrides by **directory name**: if a local target's name matches an upstream target name, SPM will try to use the local target as an override — and if their identities don't line up exactly, the resolve fails with `unable to override package … doesn't match override's identity`.

Renaming the local target to `WalletAppStorage` removes the ambiguity: there is now exactly one `WalletStorage` (eudi's credential store) and exactly one `WalletAppStorage` (our app-level state). The "App" qualifier is doing real semantic work.

---

## 🌐 Dependencies

| Dependency | Why |
|---|---|
| `DiiaCommonTypes` | Shared protocols and small value types. |
| `GRDB.swift` (`7.10.0`) | SQLite ORM for the transaction log. |
| [`WalletCore`](../WalletCore/) (`WalletCore` + `WalletDomainModels` products) | `TransactionLogStore` / `TransactionLogStorage` port protocols; `WalletDependencies` for the pass-through accessor. |

No EUDI dependencies. No networking. **No `EudiWalletKit` imports.**

---

## 🗂 Module hierarchy

```text
              ┌────────────────────────────────┐
              │       DiiaGovStackWallet        │  host app
              │   (constructs once via DI)      │
              └──────────────┬─────────────────┘
                             │
                             ▼
              ┌────────────────────────────────┐
              │        WalletAppStorage         │  ← you are here
              │   StoreHelper  TransactionLog   │
              └──────┬─────────────────┬───────┘
                     │                 │
        ┌────────────┘                 └────────────┐
        ▼                                            ▼
  UserDefaults + Keychain                        GRDB.swift
  (typed via StoringKey)                         (SQLite)
                                                     │
                                                     ▼
                                            WalletCore.WalletDependencies
                                            .transactionLogStore (port)
```

Layer: **infrastructure** — depended on by feature modules + the host.

Imports: `DiiaCommonTypes`, `GRDB`, `WalletCore`, `WalletDomainModels`.
Imported by: `WalletAuthorization`, `WalletGallery`, host app (`DiiaGovStackWallet`).

---

## ✅ Guidelines

- **Adding new persisted state:** add a `StoringKey` case (with a `k…` raw value), decide whether it belongs in UserDefaults or Keychain, and adjust `StorageType(storingKey:)` accordingly. Don't reach into `UserDefaults.standard` directly elsewhere in the codebase.
- **Keys never change.** Once a `StoringKey`'s raw value is shipped, it's part of the app's data contract. Existing users have data under those names. Renaming the swift case is fine; changing the raw value would orphan their state. If you really need to migrate, write an explicit migration that reads the old key and writes the new one before removing the old.
- **Don't use this for credentials.** Credentials go through `WalletStorage` inside `WalletEngine`. Mixing the two breaks the EUDI wall and makes credential lifecycle (revocation, key rotation, deferred issuance) harder to reason about.
- **Transaction-log writes go through the port, not the controller.** Feature modules talk to `WalletDependencies.transactionLogStorage`; only the host constructs the `TransactionLogController` and hands its store into `configure(...)`.
- **Don't expose GRDB row types outside the package.** The `GRDBTransactionLog` row type is package-internal; everything that crosses the package boundary is a domain type from `WalletDomainModels`.

---

## 📖 See also

- [`WalletCore/README.md`](../WalletCore/README.md) — the `TransactionLogStore` / `TransactionLogStorage` port definitions and how they're consumed.
- Apple's `Security.framework` Keychain documentation if you're considering a new Keychain-bound `StoringKey`.
