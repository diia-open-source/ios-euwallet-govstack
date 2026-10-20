# 🧾 WalletTransaction

> Transaction-log surface: the list of past presentations and the per-event detail view. Reads from the transaction log port; never writes.

![Targets: 1](https://img.shields.io/badge/targets-1-blue)
![Layer: Feature](https://img.shields.io/badge/layer-feature-purple)
![Size: medium](https://img.shields.io/badge/files-8-lightgrey)
![Pattern: constructor](https://img.shields.io/badge/pattern-constructor-blue)

---

## 🎯 Purpose

`WalletTransaction` renders the user-facing surface for the wallet's **presentation transaction log** — the chronological record of every time the wallet shared a credential with a verifier (OID4VP, ISO 18013-5 proximity, or any other presentation flow).

The package has two screens:

- **`TransactionsModule`** — paginated list of past transactions, grouped by date, with status badges.
- **`TransactionDetailsModule`** — per-transaction detail screen: timestamp, verifier identity, status, which claims were disclosed, which document(s) were used.

This package is **strictly read-only**. Writes happen inside `WalletEngine` (via the `DefaultTransactionLogStorage` implementation of the `TransactionLogStorage` port). Feature modules — including this one — read through the protocol port and never touch the GRDB queue directly.

---

## 🧱 Module structure

```
WalletTransaction/
└── Sources/
    └── WalletTransaction/
        ├── Common/
        │   ├── TransactionDetailsDocumentClaimsMapper.swift   # Domain → display rows
        │   └── TransactionStatusMapper.swift                  # WalletDomainError → user-visible status
        ├── TransactionDetails/
        │   ├── TransactionDetailsModule.swift                 # BaseModule for the detail screen
        │   ├── TransactionDetailsPresenter.swift              # Constructor presenter
        │   └── TransactionDetailsViewStateFactory.swift       # Detail DSConstructorModel
        └── TransactionsList/
            ├── TransactionsModule.swift                       # BaseModule for the list screen
            ├── TransactionsPresenter.swift                    # Constructor presenter
            └── TransactionsViewStateFactory.swift             # List DSConstructorModel
```

Eight files split across `Common/` (shared mappers used by both screens), `TransactionDetails/`, and `TransactionsList/`.

---

## 🔌 Public API

The package exposes one module class (the list). The detail screen is package-internal — callers reach it by tapping a row, not by constructing the module directly.

### `TransactionsModule`

```swift
public final class TransactionsModule: BaseModule {
    public init(viewStateFactory: TransactionsViewStateFactoryProtocol)
    public func viewController() -> UIViewController
}
```

Construct from the menu or wherever the user lands on "Transaction history". Pass `TransactionsViewStateFactory()` as the factory (or a stub in tests).

### `TransactionsViewStateFactoryProtocol`

```swift
public protocol TransactionsViewStateFactoryProtocol {
    func make(transactions: [TransactionLog], isLoading: Bool) -> DSConstructorModel
}

public struct TransactionsViewStateFactory: TransactionsViewStateFactoryProtocol {
    public init()
    public func make(transactions: [TransactionLog], isLoading: Bool) -> DSConstructorModel
}
```

Pure function. Groups transactions by date, sorts descending, applies the `TransactionStatusMapper` to attach a status badge, and renders a constructor model with one section per date plus a loading footer when more pages are arriving.

### Mappers (package-internal but architecturally important)

- **`TransactionStatusMapper`** — converts a `TransactionLog`'s outcome (`success` / `failed(WalletDomainError)` / `cancelled`) into a localised status string + icon. This is where the domain error → user message bridge lives for the history screen. The presentation flow uses `WalletErrorFormatter` for the in-flight error; the history screen uses this mapper for stored outcomes.
- **`TransactionDetailsDocumentClaimsMapper`** — flattens the document claims that were disclosed in a transaction into a display-ordered list of `(label, value)` rows, applying claim-display-name lookup against the issuer metadata cached at presentation time.

Both mappers are stateless and trivially testable once tests exist.

---

## 🔄 Flow

```
user opens menu → "Transaction history"
              │
              ▼
  TransactionsModule presented
              │
              ▼ on viewDidLoad
  presenter.load()
              │
              │ ── WalletDependencies.transactionLogStore.recent(limit:cursor:) ─▶ TransactionLogStore port
              │                                                                    (port lives in WalletCore;
              │                                                                     impl in WalletEngine,
              │                                                                     backing store in WalletAppStorage)
              ▼
  [TransactionLog]
              │
              ▼ TransactionsViewStateFactory.make(transactions:isLoading:)
  DSConstructorModel
              │
              ▼ render
  user taps a row
              │
              ▼
  TransactionDetailsModule presented
              │
              ▼
  TransactionDetailsPresenter loads the specific TransactionLog
              │
              ▼ TransactionDetailsDocumentClaimsMapper + TransactionStatusMapper
              ▼
  detail DSConstructorModel rendered
```

Both screens are read-only. Pagination (`recent(limit:cursor:)`) is the only write-shaped operation, and it doesn't mutate the log — it advances a cursor.

---

## 🌐 Dependencies

| Dependency | Why |
|---|---|
| `DiiaMVPModule` | MVP scaffolding. |
| `DiiaCommonTypes` | Shared protocols. |
| `DiiaCommonServices` | Common services (alerts, refresh control). |
| `DiiaUIComponents` | Constructor UI. |
| [`WalletCore`](../WalletCore/) (`WalletCore` + `WalletDomainModels`) | `TransactionLog`, `TransactionLogStore` port, `WalletDomainError`, `WalletStringKey`, `WalletDependencies` for the store accessor. |

No `WalletAppStorage` dependency — even though `WalletAppStorage` is what materialises the GRDB queue under the port, this package only sees the port.

---

## 🗂 Module hierarchy

```text
              ┌────────────────────────────────┐
              │   DiiaGovStackWallet / Menu     │
              └──────────────┬─────────────────┘
                             │ presents TransactionsModule
                             ▼
              ┌────────────────────────────────┐
              │      WalletTransaction          │  ← you are here
              │   TransactionsModule            │
              │   TransactionDetailsModule      │
              └────────────┬───────────────────┘
                           │ reads via port
                           ▼
              WalletCore.WalletDependencies.transactionLogStore
              (TransactionLogStore protocol)
                           │
                           ▼
              WalletEngine.DefaultTransactionLogStorage
                           │
                           ▼
              WalletAppStorage / GRDB
```

Layer: **leaf feature** — depended on by the menu, depends on the core ports.

---

## ✅ Guidelines

- **Read through the port.** Never inject `TransactionLogController` or any concrete type from `WalletAppStorage` into a presenter. Use `WalletDependencies.transactionLogStore` so the screen sees a `TransactionLogStore` protocol.
- **Don't write here.** Every write to the transaction log originates from `WalletEngine` when a presentation completes (or fails). If a user action seems to need a write — say, deleting an entry from history — push that capability into the port first, implement it in the engine, then call it from this package.
- **Mappers are stateless.** Both `TransactionDetailsDocumentClaimsMapper` and `TransactionStatusMapper` are deliberately free of caches. Per-presentation state lives in the `TransactionLog` value itself.
- **Status strings come from `WalletStringKey`.** The status badge text is localised via the wallet-wide string protocol; don't hardcode user-facing copy in the mappers.
- **Avoid coupling to `WalletDomainError` cases.** The mapper translates an opaque domain error into a stable user-facing status. Don't `switch` on individual error cases for behaviour beyond status presentation; if you find yourself needing it, the domain enum should grow a richer abstraction first.
- **No `EudiWalletKit` imports.** The transaction log type is a domain value; this screen never needs SDK types.

---

## 📖 See also

- [`WalletCore/README.md`](../WalletCore/README.md) — `TransactionLogStore` / `TransactionLogStorage` port definitions.
- [`WalletAppStorage/README.md`](../WalletAppStorage/README.md) — backing-store implementation owned by the host's `TransactionLogController`.
- [`WalletSharing/README.md`](../WalletSharing/README.md) — the upstream sharing flows that produce the writes this screen reads.
