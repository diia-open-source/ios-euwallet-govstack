# 🔭 WalletScannerBarcode

> AVFoundation-backed QR / barcode scanner with a camera-permission gate. Surfaces a single `QRScannerResult` via delegate or callback.

![Targets: 1](https://img.shields.io/badge/targets-1-blue)
![Layer: Feature primitive](https://img.shields.io/badge/layer-feature%20primitive-purple)
![Size: medium](https://img.shields.io/badge/files-9-lightgrey)

---

## 🎯 Purpose

`WalletScannerBarcode` is the QR / barcode scanner module the wallet uses for the two scan entry points it cares about:

- Scanning an **issuer-offer URL** from a paper or web-displayed QR code (kicks off the OID4VCI flow via the host's deeplink router).
- Scanning a **verifier presentation request URL** (kicks off the OID4VP flow).

It wraps `AVCaptureSession` + `AVCaptureMetadataOutput` in a thin abstraction (`QRCodeScannerCaptureService`), draws an overlay view with the scan rectangle and torch toggle, and exposes one extracted string back to whoever owns the module. It does **not** know what the scanned string means — interpretation is the caller's job (typically `WalletDeeplinkRouteBuilder` in the host).

A factory protocol (`QRCodeScannerModuleFactoryProtocol`) is provided so call sites can inject a module factory rather than constructing `QRCodeScannerModule` directly. This is the pattern used by `AddDocumentPresenter`, `MenuPresenter`, and `MainTabBarPresenter`.

---

## 🧱 Module structure

```
WalletScannerBarcode/
└── Sources/
    └── WalletScannerBarcode/
        ├── CameraAccessChecker.swift            # AVAuthorizationStatus gate + request helper
        ├── QRCodeScannerCaptureService.swift    # Thin wrapper over AVCaptureSession
        ├── QRCodeScannerImages.swift            # Image assets struct (torch icons, etc.)
        ├── QRCodeScannerModule.swift            # BaseModule + factory protocol/impl
        ├── QRCodeScannerOverlayView.swift       # Scan rectangle + torch button overlay
        ├── QRCodeScannerPresenter.swift         # Presenter — owns the capture lifecycle
        ├── QRCodeScannerViewController.swift    # AVPreviewLayer host
        ├── QRCodeScannerViewStateFactory.swift  # Builds the constructor-style overlay state
        └── QRScannerDelegate.swift              # QRScannerDelegate + QRScannerResult
```

Nine files. The shape is a regular MVP module plus three support files for the camera plumbing (`CameraAccessChecker`, `QRCodeScannerCaptureService`, `QRCodeScannerOverlayView`).

---

## 🔌 Public API

### `QRScannerDelegate` & `QRScannerResult`

```swift
public protocol QRScannerDelegate: AnyObject {
    func didScan(result: QRScannerResult)
}

public enum QRScannerResult {
    case success(String)
    case cancelled
    case noCameraAccess
}
```

The contract every caller must implement. `success(String)` carries the raw decoded string — interpretation belongs to the caller.

### `QRCodeScannerModuleFactoryProtocol`

```swift
public protocol QRCodeScannerModuleFactoryProtocol {
    func makeModule(delegate: QRScannerDelegate) -> BaseModule
}

public struct QRCodeScannerModuleFactory: QRCodeScannerModuleFactoryProtocol {
    public init(images: QRCodeScannerImages)
    public func makeModule(delegate: QRScannerDelegate) -> BaseModule
}
```

Inject the factory wherever a screen needs to launch a scan. The default `QRCodeScannerModuleFactory(images:)` takes a `QRCodeScannerImages` value, which lets the host theme the overlay (torch on/off icons, close icon).

### `CameraAccessChecker`

```swift
public enum CameraAccessChecker {
    public static func canUseCamera() -> Bool
    public static func requestAccess(completion: @escaping (Bool) -> Void)
}
```

Pure helper around `AVCaptureDevice.authorizationStatus(for: .video)` and `AVCaptureDevice.requestAccess(for: .video, completionHandler:)`. The presenter uses it on `viewDidAppear` to fall back to `.noCameraAccess` if the permission is denied.

### `QRCodeScannerImages`

```swift
public struct QRCodeScannerImages {
    public let torchOn: UIImage
    public let torchOff: UIImage
    public let closeIcon: UIImage
    public init(torchOn: UIImage, torchOff: UIImage, closeIcon: UIImage)
}
```

Plain value type — the host owns the asset catalog and passes images in. The package doesn't ship its own images.

---

## 🎥 Capture lifecycle

```
viewWillAppear
   │
   ▼
CameraAccessChecker.canUseCamera() ───── no ──▶ delegate.didScan(.noCameraAccess)
   │ yes
   ▼
QRCodeScannerCaptureService.start()
   │
   ▼ (AVCaptureMetadataOutput emits a string)
delegate.didScan(.success("…")) + scanner dismisses itself
   │
   ▼
caller's flow takes over (deeplink routing, document add, etc.)
```

The presenter owns the capture service and torch state. Pause/resume is automatic on `viewWillDisappear`/`viewWillAppear`. The view controller is a thin `UIViewController` that hosts the `AVCaptureVideoPreviewLayer` and the overlay view; everything else flows through the presenter.

---

## 🌐 Dependencies

| Dependency | Why |
|---|---|
| `DiiaMVPModule` | MVP scaffolding. |
| `DiiaCommonTypes` | Shared protocols. |
| `DiiaUIComponents` | UI primitives used by the overlay. |
| [`WalletCore`](../WalletCore/) | `WalletStringKey` for localised "Allow camera access" / "Scan a code" text. |
| `AVFoundation` (Apple) | Capture session, metadata output. |
| `UIKit` (Apple) | View controller, preview layer host. |

No third-party deps. No EUDI symbols. No networking.

---

## 🗂 Module hierarchy

```text
              ┌────────────────────────────────┐
              │   Wallet feature presenters     │
              │   (AddDocument, Menu,           │
              │    MainTabBar)                  │
              └──────────────┬─────────────────┘
                             │ inject QRCodeScannerModuleFactoryProtocol
                             ▼
              ┌────────────────────────────────┐
              │      WalletScannerBarcode       │  ← you are here
              │   QRCodeScannerModule           │
              │   QRCodeScannerCaptureService   │
              │   CameraAccessChecker           │
              └────────────┬───────────────────┘
                           │
                           ▼
                  AVFoundation / UIKit
```

Layer: **feature primitive** — a reusable scanner that doesn't know the wallet domain.
Imports: `DiiaMVPModule`, `DiiaCommonTypes`, `DiiaUIComponents`, `WalletCore` (for strings only), `AVFoundation`, `UIKit`.
Imported by: feature SPMs that need a scan entry point (today: `WalletAddDocument`, `WalletMenu`, and the host's `MainTabBar`).

---

## ✅ Guidelines

- **Inject the factory, don't construct the module directly.** Holding a `QRCodeScannerModuleFactoryProtocol` makes the consumer testable and keeps the scanner module decoupled from how it gets created.
- **The scanner does not interpret payloads.** It returns the raw decoded string. If you want to validate the URL scheme, do it in the caller (e.g. via `WalletDeeplinkRouteBuilder.canCreateRoute(with:)`).
- **Permission denial is a normal state, not an error.** `.noCameraAccess` is a `QRScannerResult` case — handle it explicitly in your delegate. Don't assume `.success(...)` is the only outcome.
- **No `EudiWalletKit` imports.** Scanning is camera plumbing; nothing here should depend on `WalletEngine` or any credential type.
- **Torch behaviour belongs in the overlay view.** If you find yourself wiring torch state from the presenter, the overlay needs a richer model — don't leak `AVCaptureDevice.torchMode` calls into the presenter.

---

## 📖 See also

- [`WalletAddDocument/README.md`](../WalletAddDocument/README.md) — typical consumer; injects `QRCodeScannerModuleFactoryProtocol`.
- [`DiiaGovStackWallet/Common/Services/WalletQRScannerHelper.swift`](../../DiiaGovStackWallet/Common/Services/WalletQRScannerHelper.swift) — host-side helper that adapts `QRScannerDelegate` to the host's deeplink routing.
- `AVCaptureMetadataOutput` documentation for the underlying iOS capture machinery.
