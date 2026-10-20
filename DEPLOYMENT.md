# Deployment and Configuration Guide (iOS)

This guide covers building, signing, distributing, and configuring the iOS wallet app `DiiaGovStackWallet`.
The target audience is iOS developers and QA engineers shipping debug builds for internal use and release builds to TestFlight.

For repository orientation, see `README.md`.
For contribution rules, see `CONTRIBUTING.md`.

## 1. Prerequisites

### 1.1 System requirements

| Requirement | Version |
|---|---|
| macOS | A version supporting Xcode 15+ |
| Xcode | 15.0 or newer |
| Swift | 5.0 (toolchain), packages use Swift tools 5.6 / 5.7 / 5.8 |
| iOS deployment target (app) | 16.0 |
| iOS deployment target (foundational SPM packages) | 15.0 |
| iOS deployment target (wallet SPM packages) | 16.0 |
| Disk space | Enough for the repo, DerivedData, and ~37 SPM packages |

### 1.2 Apple Developer access

The required level of access depends on which distribution flow you use (see section 3).

| Flow | Required access |
|---|---|
| Standard Xcode Organizer flow (section 3.1) | Apple Developer Program seat with access to the Release `DEVELOPMENT_TEAM` (`<TEAM_ID_RELEASE>`) and authority to manage certificates/profiles. |
| Decentralized signing flow (section 3.2), account owner | Apple Developer Program seat owning the Release team (`<TEAM_ID_RELEASE>`), App Store Connect access to invite testers. |
| Decentralized signing flow (section 3.2), individual developer | An Apple ID with App Manager role on the App Store Connect app record, plus a `.p12` distribution certificate and `.mobileprovision` from the owner. |

### 1.3 Tooling

- Xcode command-line tools (`xcode-select --install`).
- Optional: Transporter from the Mac App Store, used in section 3.2 for uploading `.ipa` files without sharing the owner's Apple ID.
- Optional: OpenSSL, for the decentralized signing flow's certificate generation.

### 1.4 Repository access

You need read access to the Git repository.
Clone with submodules disabled (none are used) and check out the release branch you intend to ship.

```bash
git clone <repo-url> wallet
cd wallet
git checkout <release-branch>
```

The current release branch in active use is `release/v.2026.05.31-revoked-debug`.
Branch naming convention: `release/v.<YYYY.MM.DD>-<slug>`.

## 2. Build Configuration

### 2.1 Project layout

- The repository is opened as a plain Xcode project: `DiiaGovStackWallet.xcodeproj`.
- There is no top-level `.xcworkspace`; Xcode generates its own inner workspace for SPM resolution.
- Local Swift packages live under `LocalPackages/` as siblings of the `.xcodeproj`.
- `Package.resolved` is committed at `DiiaGovStackWallet.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`, so SPM pins are reproducible across machines.
- The project uses folder references; new files added to existing on-disk folders are picked up automatically without editing `project.pbxproj`.

### 2.2 Scheme

The project ships a single shared scheme: `DiiaGovStackWallet` (`xcshareddata/xcschemes/DiiaGovStackWallet.xcscheme`).

| Action | Configuration |
|---|---|
| Run | Debug |
| Test | Debug |
| Analyze | Debug |
| Profile | Release |
| Archive | Release |

`parallelizeBuildables = YES` and `buildImplicitDependencies = YES`.
All five build-for flags (testing, running, profiling, archiving, analyzing) are enabled.
No `xcuserdata/*.xcscheme` overrides exist.

### 2.3 Configurations

Both project-level and target-level `XCConfigurationList`s set `defaultConfigurationName = Release`.
There are no `.xcconfig` files; all settings are inlined in `project.pbxproj`.

#### 2.3.1 Project-level differences (Debug vs Release)

| Setting | Debug | Release |
|---|---|---|
| `DEBUG_INFORMATION_FORMAT` | `dwarf` | `dwarf-with-dsym` |
| `ENABLE_TESTABILITY` | `YES` | not set |
| `ENABLE_NS_ASSERTIONS` | not set | `NO` |
| `GCC_DYNAMIC_NO_PIC` | `NO` | not set |
| `GCC_OPTIMIZATION_LEVEL` | `0` | not set |
| `GCC_PREPROCESSOR_DEFINITIONS` | `DEBUG=1, $(inherited)` | not set |
| `MTL_ENABLE_DEBUG_INFO` | `INCLUDE_SOURCE` | `NO` |
| `ONLY_ACTIVE_ARCH` | `YES` | not set |
| `SWIFT_ACTIVE_COMPILATION_CONDITIONS` | `DEBUG` | not set |
| `SWIFT_OPTIMIZATION_LEVEL` | `-Onone` | `-O` |
| `SWIFT_COMPILATION_MODE` | not set | `wholemodule` |
| `VALIDATE_PRODUCT` | not set | `YES` |

Identical across both at project level: `IPHONEOS_DEPLOYMENT_TARGET = 16.2`, `SDKROOT = iphoneos`, `DEVELOPMENT_TEAM = <TEAM_ID_DEBUG>`, `ENABLE_USER_SCRIPT_SANDBOXING = YES`, `STRING_CATALOG_GENERATE_SYMBOLS = YES`, `GCC_C_LANGUAGE_STANDARD = gnu11`, `CLANG_CXX_LANGUAGE_STANDARD = gnu++20`, the full suite of `CLANG_WARN_*` / `GCC_WARN_*` flags, `MTL_FAST_MATH = YES`.

#### 2.3.2 Target-level differences (Debug vs Release)

| Setting | Debug | Release |
|---|---|---|
| `PRODUCT_BUNDLE_IDENTIFIER` | `ua.wallet.dev.test` | `ua.govstack.digitalwallet.app.dev` |
| `CODE_SIGN_STYLE` | `Automatic` | `Manual` |
| `CODE_SIGN_IDENTITY` (base) | `Apple Development` | `Apple Development` |
| `CODE_SIGN_IDENTITY[sdk=iphoneos*]` | not set | `iPhone Distribution` |
| `DEVELOPMENT_TEAM` (base) | `<TEAM_ID_DEBUG>` | `""` |
| `DEVELOPMENT_TEAM[sdk=iphoneos*]` | not set | `<TEAM_ID_RELEASE>` |
| `PROVISIONING_PROFILE_SPECIFIER` (base) | `""` | `""` |
| `PROVISIONING_PROFILE_SPECIFIER[sdk=iphoneos*]` | not set | `Diia_GovStack_Wallet_distribution` |

Identical across both at target level: `MARKETING_VERSION = 0.0.1`, `CURRENT_PROJECT_VERSION = 1`, `IPHONEOS_DEPLOYMENT_TARGET = 16.0` (target value overrides the project-level 16.2), `SWIFT_VERSION = 5.0`, `TARGETED_DEVICE_FAMILY = 1` (iPhone-only), `GENERATE_INFOPLIST_FILE = YES`, `INFOPLIST_FILE = DiiaGovStackWallet/Info.plist`, `SUPPORTED_PLATFORMS = "iphoneos iphonesimulator"`, `SUPPORTS_MACCATALYST = NO`, `SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD = NO`, all `INFOPLIST_KEY_*` values (see section 2.4), `ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon`, `ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor`, `LD_RUNPATH_SEARCH_PATHS = ($(inherited), @executable_path/Frameworks)`, `SWIFT_EMIT_LOC_STRINGS = YES`, `PRODUCT_NAME = $(TARGET_NAME)`.

Note that Debug and Release use two different `DEVELOPMENT_TEAM` IDs: `<TEAM_ID_DEBUG>` for Debug, `<TEAM_ID_RELEASE>` for Release device builds.
The named provisioning profile `Diia_GovStack_Wallet_distribution` is owned by the Release team.

### 2.4 Auto-generated Info.plist keys

These are inlined as `INFOPLIST_KEY_*` build settings, identical for Debug and Release.

| Key | Value |
|---|---|
| `CFBundleDisplayName` | `Diia GovStack Wallet` |
| `LSApplicationCategoryType` | `""` (empty) |
| `NSBluetoothAlwaysUsageDescription` | `This app uses Bluetooth to share identity documents with verifiers nearby.` |
| `NSCameraUsageDescription` | `This app needs camera access to scan QR codes and barcodes.` |
| `NSFaceIDUsageDescription` | `This app uses Face ID to securely sign and share your identity documents.` |
| `UIApplicationSupportsIndirectInputEvents` | `YES` |
| `UILaunchStoryboardName` | `LaunchScreen` |
| `UISupportedInterfaceOrientations` | `UIInterfaceOrientationPortrait` |
| `UISupportedInterfaceOrientations~ipad` | All four orientations (unreachable since `TARGETED_DEVICE_FAMILY = 1`) |
| `UIUserInterfaceStyle` | `Light` |

### 2.5 Explicit Info.plist

File: `DiiaGovStackWallet/Info.plist`.

- `CFBundleURLTypes` — one entry with role `Editor` registering the URL schemes `haip-vci`, `openid-credential-offer`, `haip-vp`, `haip`, `eudi-openid4vp`, `mdoc-openid4vp`, `openid4vp` (OID4VCI issuance and OID4VP presentation deeplinks).
- `Configuration = DiiaStage` — informational key consumed by app code.
- `UIAppFonts` — `e-Ukraine-Regular.otf`, `e-Ukraine-Bold.otf`, `e-Ukraine-Light.otf`, `e-Ukraine-Medium.otf`, `e-UkraineHead-Regular.otf`, `e-UkraineHead-Light.otf`.
- `UIApplicationSceneManifest = { UIApplicationSupportsMultipleScenes = false }` — single-scene app.

### 2.6 SPM package inventory

Two deployment-target tiers exist across local packages.
The host app pins to iOS 16, matching the wallet packages.

| Package | Purpose | iOS Target | Swift Tools |
|---|---|---|---|
| `ios-mvpmodule` (`DiiaMVPModule`) | Foundational MVP base classes | 15 | 5.6 |
| `commontypes` (`DiiaCommonTypes`) | Cross-package value types/protocols | 15 | 5.8 |
| `ios-core-uicomponents` (`DiiaUIComponents`) | Diia design-system UI kit | 15 / macOS 10.15 | 5.7 |
| `core-common-services` (`DiiaCommonServices`) | Reusable service flows | 15 | 5.7 |
| `WalletDocuments` | Document UI/common types + animations | 15 | 5.8 |
| `WalletCore` | EUDI integration core; the only place that imports EudiWalletKit / Mdoc / WalletStorage | 16 | 5.8 |
| `WalletAppStorage` | GRDB-backed local persistence | 16 | 5.8 |
| `WalletAuthorization` | Auth + PIN code flows | 16 | 5.8 |
| `WalletAddDocument` | Add-document feature | 16 | 5.8 |
| `WalletContextMenu` | Document context-menu module | 16 | 5.8 |
| `WalletGallery` | Gallery / document carousel | 16 | 5.8 |
| `WalletIssuing` | Credential issuance flow | 16 | 5.8 |
| `WalletMenu` | Settings / menu screens | 16 | 5.8 |
| `WalletScannerBarcode` | QR/barcode scanner | 16 | 5.8 |
| `WalletSharing` | OpenID4VP presentation/sharing flow | 16 | 5.8 |
| `WalletSplashScreen` | Launch/splash UI | 16 | 5.8 |
| `WalletTransaction` | Transaction history view | 16 | 5.8 |

### 2.7 EUDI stack and major remote dependencies

Pinned versions from `Package.resolved`:

| Dependency | Resolved Version |
|---|---|
| `eudi-lib-ios-wallet-kit` | 0.30.1 |
| `eudi-lib-ios-openid4vci-swift` | 0.38.1 |
| `eudi-lib-ios-siop-openid4vp-swift` | 0.33.1 |
| `eudi-lib-ios-iso18013-data-model` | 0.20.0 |
| `eudi-lib-ios-iso18013-data-transfer` | 0.20.0 |
| `eudi-lib-ios-iso18013-security` | 0.20.0 |
| `eudi-lib-ios-wallet-storage` | 0.20.0 |
| `eudi-lib-ios-statium-swift` | 0.4.0 |
| `eudi-lib-sdjwt-swift` | 0.14.3 |
| `grdb.swift` | 7.10.0 |
| `swift-crypto` | 3.15.1 |
| `swift-certificates` | 1.19.1 |
| `swift-asn1` | 1.7.0 |
| `JOSESwift` | 3.0.0 |
| `jose-swift` | 6.0.4 |
| `SwiftMessages` | 9.0.9 |
| `Kingfisher` | 7.12.0 |
| `lottie-spm` | 4.6.0 |
| `ReactiveKit` | 3.16.2 |

### 2.8 DEBUG macro propagation in SPM

SPM does not forward the host app's `DEBUG` macro into package targets.
Any `#if DEBUG` block inside a package silently no-ops in Debug builds unless the target opts in via `.define("DEBUG", .when(configuration: .debug))`.

No local package currently opts in — there are no `#if DEBUG` blocks in the local packages.
If you add one, remember it will be dead in every configuration unless that target opts in via `.define("DEBUG", .when(configuration: .debug))`.

### 2.9 Build steps (Xcode)

1. Open `DiiaGovStackWallet.xcodeproj` in Xcode 15+.
2. Wait for SPM resolution to complete (~17 local + ~20 remote packages, several minutes on a cold clone).
3. Select the `DiiaGovStackWallet` scheme.
4. Choose a destination (Simulator for Debug, generic iOS device or connected device for Release/Archive).
5. Build via Product → Build (Debug) or Product → Archive (Release).

### 2.10 Build steps (CLI)

Use this recipe for headless Debug builds.
The `Swiftlint Run Script` build phase honours `SKIP_SWIFTLINT=1` and exits early, surfacing only Swift compile errors.

```bash
xcodebuild -project DiiaGovStackWallet.xcodeproj \
  -scheme DiiaGovStackWallet \
  -destination 'generic/platform=iOS Simulator' \
  -configuration Debug \
  -skipPackagePluginValidation \
  -skipMacroValidation \
  ENABLE_USER_SCRIPT_SANDBOXING=NO \
  SKIP_SWIFTLINT=1 \
  build 2>&1 > /tmp/wallet-build.log; echo "EXITCODE=$?" >> /tmp/wallet-build.log
```

Flag rationale:
- `SKIP_SWIFTLINT=1` — bypasses the project's SwiftLint build phase.
- `ENABLE_USER_SCRIPT_SANDBOXING=NO` — required because the project sets sandboxing to `YES` and the SwiftLint script needs to read sources.
- `-skipPackagePluginValidation` and `-skipMacroValidation` — suppress interactive prompts that block headless runs.

Check outcome with `tail -3 /tmp/wallet-build.log` (look for `EXITCODE=0`) or `grep -nE 'error:' /tmp/wallet-build.log`.

To resolve the SPM package graph only, without compiling:

```bash
xcodebuild -resolvePackageDependencies \
  -project DiiaGovStackWallet.xcodeproj \
  -scheme DiiaGovStackWallet
```

### 2.11 Versioning

Both Debug and Release ship with `MARKETING_VERSION = 0.0.1` and `CURRENT_PROJECT_VERSION = 1`.
The bundle identifier is the only customer-facing differentiator between configurations.

Before each TestFlight upload, increment `CURRENT_PROJECT_VERSION` (build number) so App Store Connect accepts the new build.
Bump `MARKETING_VERSION` only when a new user-visible release version is intended.
Both values are set in target build settings.

## 3. Release and Distribution (TestFlight)

This project supports two distribution flows.
Pick the one that matches your team's Apple Developer Program structure.

| Flow | When to use |
|---|---|
| 3.1 Standard | Team has multiple Apple Developer Program seats on the Release team `<TEAM_ID_RELEASE>`, each developer can manage their own certificates. |
| 3.2 Decentralized | The Release team is a personal Apple Developer account that cannot add additional seats, but multiple developers must be able to upload TestFlight builds without sharing the owner's Apple ID. |

Both flows produce builds with bundle ID `ua.govstack.digitalwallet.app.dev`, signed by the `Diia_GovStack_Wallet_distribution` provisioning profile under team `<TEAM_ID_RELEASE>`.

### 3.1 Standard flow (Xcode Organizer)

This is the recommended flow for teams with full Apple Developer Program access.

1. Bump `CURRENT_PROJECT_VERSION` in the target's Release build settings.
2. Select the `DiiaGovStackWallet` scheme and the destination "Any iOS Device (arm64)".
3. Product → Archive.
4. When the archive completes, Xcode opens Organizer.
5. Select the new archive and click "Distribute App".
6. Choose "App Store Connect" → "Upload".
7. Confirm the signing certificate (Apple Distribution under team `<TEAM_ID_RELEASE>`) and the provisioning profile `Diia_GovStack_Wallet_distribution`.
8. Click "Upload".
9. Wait for processing in App Store Connect (typically 10–30 minutes).
10. Once processing finishes, the build appears under TestFlight → Builds.
11. Assign the build to internal and/or external tester groups.

If signing fails in step 7, verify the certificate and provisioning profile are installed in the Keychain and Xcode's "Accounts" preferences include the Release team.

### 3.2 Decentralized signing flow

Use this flow when a single personal Apple Developer account owns the Release team and individual developers must be able to upload TestFlight builds independently.
The owner produces signing material once; each developer reuses it locally.

#### Part 1: account owner setup

These steps are performed once by the holder of the Apple Developer Program account (team `<TEAM_ID_RELEASE>`).

**1. Invite developers to App Store Connect.**

In App Store Connect → Users and Access → People, invite each developer using their personal Apple ID and assign the role **App Manager**.
The App Manager role grants TestFlight upload rights without granting access to the Developer Portal (certificates and identifiers).

**2. Generate a distribution certificate via OpenSSL.**

Generate a private key and a Certificate Signing Request:

```bash
openssl genrsa -out distribution.key 2048

openssl req -new -key distribution.key -out distribution.csr \
  -subj "/emailAddress=<owner-email>/CN=<owner-name>/C=<country-code>"
```

Upload `distribution.csr` to the Apple Developer Portal: Certificates, Identifiers & Profiles → Certificates → "+" → Apple Distribution.
Download the resulting `distribution.cer`.

Convert the certificate plus private key into a `.p12` bundle that can be shared with developers:

```bash
openssl x509 -in distribution.cer -inform DER -out distribution.pem -outform PEM

openssl pkcs12 -export \
  -inkey distribution.key \
  -in distribution.pem \
  -out distribution.p12 \
  -name "iPhone Distribution: <team-name>"
```

When prompted, set a strong export password.
Communicate this password to developers out of band (not in the same channel as the `.p12` file).

**3. Create a provisioning profile.**

In the Developer Portal: Profiles → "+" → App Store → select the App ID for `ua.govstack.digitalwallet.app.dev` → select the distribution certificate created above → name it `Diia_GovStack_Wallet_distribution` to match the project's `PROVISIONING_PROFILE_SPECIFIER`.
Download the resulting `.mobileprovision` file.

**4. Distribute the signing material.**

Hand each developer:
- `distribution.p12`
- The `.p12` export password (via a separate secure channel)
- `Diia_GovStack_Wallet_distribution.mobileprovision`

Refresh the profile and re-distribute when it expires (one year) or when its certificate is rotated.

#### Part 2: developer steps

Each developer performs these steps once on their machine, then repeats only steps 5–10 for each release.

**1. Import the `.p12` into the Keychain.**

Double-click `distribution.p12` in Finder.
Enter the export password supplied by the owner.
Keychain Access shows the certificate (`iPhone Distribution: <team-name>`) and its private key under the "login" keychain.

**2. Import the `.mobileprovision`.**

Double-click `Diia_GovStack_Wallet_distribution.mobileprovision`.
Xcode installs it automatically.
Verify in Xcode → Settings → Accounts → (your team) → Manage Profiles that the profile is listed.

**3. Disable automatic signing for Release.**

In Xcode, open the `DiiaGovStackWallet` target → Signing & Capabilities → tab "Release".
Uncheck "Automatically manage signing".
Set:
- Team: the Release team `<TEAM_ID_RELEASE>` (it may appear by name).
- Provisioning Profile: `Diia_GovStack_Wallet_distribution`.
- Signing Certificate: `Apple Distribution` (resolved from the imported `.p12`).

These settings should already be present in `project.pbxproj`.
If Xcode complains it cannot find the team, you are signed in to App Store Connect with your own Apple ID (App Manager) but do not need to be added to the Developer Portal — the local `.p12` and `.mobileprovision` are sufficient for archiving.

**4. Bump the build number.**

Increment `CURRENT_PROJECT_VERSION` in the target's Release build settings.

**5. Archive.**

Select the `DiiaGovStackWallet` scheme and destination "Any iOS Device (arm64)".
Product → Archive.

**6. Export the `.ipa` (do not upload via Xcode).**

When Organizer opens, select the archive and click "Distribute App".
Choose **"Custom"** → **"App Store Connect"** → **"Export"** (NOT "Upload").
Select the manual signing options matching step 3.
Save the resulting `.ipa` to a local folder.

The export path is required because the developer's Apple ID is not in the Developer Portal, so Xcode's "Upload" path cannot authenticate against the Release team's account.

**7. Upload the `.ipa` via Transporter.**

Open Transporter (Mac App Store).
Sign in with your own Apple ID (the one invited to App Store Connect as App Manager).
Drag the exported `.ipa` into the Transporter window.
Click "Deliver".
Transporter authenticates with your App Manager credentials and uploads the build to the app record owned by the Release team.

**8. Verify in TestFlight.**

Sign in to App Store Connect with your Apple ID.
Open the app record → TestFlight → Builds.
The build appears with status "Processing" and transitions to "Ready to Test" once Apple's pipeline finishes (typically 10–30 minutes).
Assign it to internal or external testers as needed.

### 3.3 Tester management

Independent of the upload flow:
- Internal testers are added in App Store Connect → TestFlight → Internal Group; they receive builds immediately after processing.
- External testers require a "What to Test" note and Apple review on the first build of a new `MARKETING_VERSION`.
- TestFlight builds expire 90 days after upload.

### 3.4 dSYM and symbolication

Release archives produce dSYMs because `DEBUG_INFORMATION_FORMAT = dwarf-with-dsym` is set for Release.
Xcode includes them in the archive bundle (Organizer → "Show in Finder" → "Show Package Contents" → `dSYMs/`).
Upload them to whatever crash-reporting backend is in use; the project does not bundle a crash-reporter SDK.

## 4. Troubleshooting

### 4.1 SPM resolution and build

| Symptom | Cause / Fix |
|---|---|
| `Unable to resolve module dependency` after adding sources to a package | A transitive import was missed in the target's `dependencies:` list in `Package.swift`. Audit every non-system import in the moved files against the target's declared deps. See the EUDI wall canary note in `README.md`. |
| `Multiple commands produce …` | A resource file (typically a Lottie `.json`) is duplicated between `WalletDocuments` and `ios-core-uicomponents`. Remove the duplicate from one package. |
| `#if DEBUG` block silently inactive in a package | The package target is missing `.define("DEBUG", .when(configuration: .debug))` in its `swiftSettings`. Either move the code to `WalletCore` or `WalletGallery`, or add the setting. See section 2.8. |
| Cold SPM resolve takes a long time | Expected — 17 local plus ~20 remote packages. Subsequent resolves are cached. |
| CLI build fails inside the SwiftLint script phase | Use the CLI recipe in section 2.10 with `SKIP_SWIFTLINT=1` and `ENABLE_USER_SCRIPT_SANDBOXING=NO`. |
| `customModule=` storyboard crash at launch | See `README.md` troubleshooting. |
| `WalletDependencies` bootstrap-order trap | See `README.md` and `LocalPackages/WalletCore/README.md`. Never pass `EudiWalletKitController.instance` (or any value reading other `WalletDependencies` slots) as a `configure(...)` argument; use separate `set*(_:)` methods. |
| `LoggingSystem.bootstrap` crash on second call | Only `WalletCore` should bootstrap the logging system. The host must not call `LoggingSystem.bootstrap` again. Still present in EudiWalletKit 0.30.1. |
| Accidental `import JOSESwift` when `jose_swift` was intended | Two JOSE libraries coexist (`JOSESwift` 3.0.0 and `jose-swift` 6.0.4). Verify the import line matches the API you actually call. |

### 4.2 Signing and archiving

| Symptom | Cause / Fix |
|---|---|
| Xcode cannot find the Release team during archive | The Release `DEVELOPMENT_TEAM` `<TEAM_ID_RELEASE>` differs from the Debug team `<TEAM_ID_DEBUG>`. In the decentralized flow this is expected — `.p12` and `.mobileprovision` are sufficient without team membership. In the standard flow, add the team in Xcode → Settings → Accounts. |
| `No matching provisioning profile found` | The profile `Diia_GovStack_Wallet_distribution` is not installed. Double-click the `.mobileprovision` file, or re-download from the Developer Portal. |
| Profile does not match bundle ID | Confirm the profile is for `ua.govstack.digitalwallet.app.dev` (Release). The Debug profile (`ua.wallet.dev.test`) cannot be used for distribution. |
| `Apple Distribution` certificate not in Keychain | Re-import the `.p12`; ensure both certificate and private key are present under the "login" keychain. |
| Xcode insists on automatic signing | Confirm `CODE_SIGN_STYLE = Manual` is set for Release in the target build settings; do not change this at the project level. |

### 4.3 TestFlight upload

| Symptom | Cause / Fix |
|---|---|
| Transporter rejects with "duplicate build number" | Bump `CURRENT_PROJECT_VERSION` and re-archive. |
| Build stuck in "Processing" for hours | Apple-side delay. If it exceeds ~24h, contact Apple Developer Support. Check email for processing errors. |
| `ITSAppUsesNonExemptEncryption` warning | Add the key to `Info.plist` (or `INFOPLIST_KEY_*`) with the appropriate value once an export-compliance determination has been made. Not currently set in the project. |
| Xcode Organizer Upload fails to authenticate (decentralized flow) | Expected — developers are App Managers in App Store Connect, not seat-holders in the Developer Portal. Use the Export + Transporter path in section 3.2. |

### 4.4 Trust and runtime

See section 5 for trust-related runtime behaviour.
Briefly:

- Missing `.der` certificate file → logged with `[E2E][TrustStore] ❌` and silently skipped, not a crash.
- Missing or malformed `wallet-config.json` → `fatalError` at launch (see section 5.5).
- Verifier reader-auth `nil` → treated as trusted (lenient gate). This is deliberate; do not flip without policy approval.

## 5. Wallet Configuration

The runtime wallet configuration is defined in JSON and consumed at app launch.

### 5.1 Configuration file

Path: `DiiaGovStackWallet/Common/Wallet/Configuration/wallet-config.json`.

Current contents:

```json
{
  "issuers": [
    { "host": "bb-wallet-issuer.demo3.ukrohost.com", "displayPriority": 2, "metadataTrustRoots": ["PID-Issuer-CA"] },
    { "host": "issuer.eudiw.dev",                    "displayPriority": 1, "metadataTrustRoots": ["pidissuerca02_ut"] },
    { "host": "issuer-backend.eudiw.dev",            "displayPriority": 0, "metadataTrustRoots": ["pidissuerca02_ut"] }
  ],
  "verifierReaderTrustRoots": [
    "pidissuerca02_cz", "pidissuerca02_ee", "pidissuerca02_eu", "pidissuerca02_lu",
    "pidissuerca02_nl", "pidissuerca02_pt", "pidissuerca02_ut", "r45_staging", "esoz_cert"
  ]
}
```

The sibling file `wallet-config-README.md` in the same folder is the schema's source of truth.

### 5.2 Schema

Top-level fields:

| Field | Type | Controls |
|---|---|---|
| `issuers` | `[IssuerConfig]` | Per-issuer entries. Defines the picker order in `DocumentsCollectionContextImpl` and the per-host VCI configuration map in `WalletKitConfig.vciConfig`. |
| `verifierReaderTrustRoots` | `[String]` | Global list of DER filenames (no extension) used as trust anchors for verifier reader-auth certificates during BLE / OpenID4VP presentations. Consumed by `WalletKitConfig.trustedReaderRoots`. |

`IssuerConfig` fields (see `LocalPackages/WalletCore/Sources/WalletDomainModels/Configuration/WalletConfiguration.swift` lines 11–15):

| Field | Type | Meaning |
|---|---|---|
| `host` | `String` | Issuer hostname without scheme. Used as the lookup key; `https://<host>` becomes the `credentialIssuerURL` in `OpenId4VciConfiguration`. |
| `displayPriority` | `Int` | Sort order in the "Add document" picker; higher first. Consumed in `DocumentsCollectionContextImpl.swift` lines 227-228. |
| `metadataTrustRoots` | `[String]` | DER filenames (no extension) accepted as anchors when validating the issuer's signed OID4VCI metadata JWT (`x5c` header). Per-issuer scoping is enforced by `issuerMetadataRoots(for:)` in `WalletKitConfig.swift` lines 75-80. |

Fields explicitly **not** in JSON (they live in code and are global to the build):

- `authFlowRedirectionURI` — hard-coded `eu.europa.ec.euidi://authorization` in `WalletKitConfig.swift` lines 29-31.
- `clientId` — hard-coded `"wallet-dev"` in `WalletKitConfig.swift` line 47.
- `walletProviderBaseURL` — hard-coded `https://wallet-provider.eudiw.dev` in `WalletKitConfig.swift` line 14.

### 5.3 Loader and bootstrap

- Struct: `WalletConfiguration` at `LocalPackages/WalletCore/Sources/WalletDomainModels/Configuration/WalletConfiguration.swift` lines 7–42.
  Plain `Codable` struct; exposes `static var shared` backed by `_shared: WalletConfiguration?` and a `configure(_:)` setter (lines 23–33).
- Bootstrap call site: `DiiaGovStackWallet/AppConfigurator.swift` lines 94–105 (`bootstrapWalletConfiguration()`).
  Loads `wallet-config.json` from `Bundle.main`, decodes with `JSONDecoder`, calls `WalletConfiguration.configure(config)`.

### 5.4 Trust certificates

Folder: `DiiaGovStackWallet/Common/Wallet/Certificates/`.

Currently bundled DER files (all referenced from `wallet-config.json`):

| File | Size | Role |
|---|---|---|
| `PID-Issuer-CA.der` | 410 B | Issuer-metadata root for `bb-wallet-issuer.demo3.ukrohost.com`. Not a verifier CA (see comment in `WalletKitConfig.swift` line 69). |
| `pidissuerca02_ut.der` | 737 B | Issuer-metadata root for `issuer.eudiw.dev` and `issuer-backend.eudiw.dev`; also a verifier reader-auth root. |
| `pidissuerca02_cz.der` | ~727 B | Verifier reader-auth root (CZ IACA). |
| `pidissuerca02_ee.der` | ~727 B | Verifier reader-auth root (EE IACA). |
| `pidissuerca02_eu.der` | ~727 B | Verifier reader-auth root (EU IACA). |
| `pidissuerca02_lu.der` | ~727 B | Verifier reader-auth root (LU IACA). |
| `pidissuerca02_nl.der` | ~727 B | Verifier reader-auth root (NL IACA). |
| `pidissuerca02_pt.der` | ~727 B | Verifier reader-auth root (PT IACA). |
| `r45_staging.der` | 1546 B | Verifier reader-auth staging root. |
| `esoz_cert.der` | 923 B | Verifier reader-auth root. |

Loader: `LocalPackages/WalletCore/Sources/WalletEngine/Kit/WalletKitConfig.swift` (`loadCerts(_:)` lines 82–100).
Files are loaded via `Bundle.main.url(forResource:withExtension:"der")` then `SecCertificateCreateWithData`.
Missing or invalid DERs are logged with `[E2E][TrustStore] ❌` and skipped silently — they do not crash the app, they just remove that anchor from the trust list.

Usage split:

- **Verifier reader-auth trust** (`trustedReaderRoots` line 70): the EU IACAs plus `r45_staging` and `esoz_cert`, passed to EudiWalletKit as `trustedReaderRootCertificates` (`WalletKitController.swift` line 56).
- **Issuer metadata trust** (`issuerMetadataRoots(for:)` line 75): scoped per-issuer via `WalletCertificateChainTrust` under `.preferSigned` policy on `IssuerMetadataPolicy`.
- **Issuer document trust** (SD-JWT `x5c` / mDoc `x5chain` MSO chain validation): **not wired**. TODO at `WalletKitConfig.swift` lines 40-44 — blocked on EudiWalletKit 0.30.1 stub and a bb-wallet-issuer cert split. Document signatures are currently accepted without chain validation.

To add a new trust root:

1. Drop the `.der` file into `DiiaGovStackWallet/Common/Wallet/Certificates/`.
2. The project uses folder references, so no Xcode project edits are needed.
3. Reference the file by basename (no `.der` extension) in either `issuers[].metadataTrustRoots` or `verifierReaderTrustRoots` in `wallet-config.json`.

### 5.5 Validation behaviour

Fail-fast at app launch (`AppConfigurator.swift` lines 94-105):

- Missing bundle resource → `fatalError("wallet-config.json not found in app bundle …")`.
- JSON decode error → `fatalError("Failed to decode wallet-config.json: \(error)")`.
- Reading `WalletConfiguration.shared` before `configure(_:)` ran → `fatalError(…)` (`WalletConfiguration.swift` line 25).

There is no schema validator beyond `Codable`.
Certificate-file references in JSON are validated lazily at first use in `loadCerts` and degrade silently (log and skip).
A typo in a trust-root name removes the anchor from the trust list rather than crashing.

### 5.6 Security-sensitive flags

The JSON config has no `ALLOW_UNTRUSTED_*` or `ENFORCE_*` switches.
Trust behaviour is hard-coded in Swift:

- **Issuer-metadata policy** (`WalletKitConfig.swift` lines 19-23): `.preferSigned(...)`.
  Accepts signed JWT when present, falls back to plain JSON otherwise.
  The strict-mode switch is `.requireSigned(...)`; flipping it requires policy approval.
- **Verifier reader-auth gate** (`WalletRemoteSessionManager.swift` line 132 and `WalletProximitySessionManager.swift` line 175): `let isTrusted = session.readerCertIssuerValid != false`.
  Lenient: blocks only on explicit `false`, treats `nil` as trusted.
  A TODO above flags this for strict-mode reconsideration once verifiers populate `readerAuthCertificate`.
  Do not flip to strict without policy approval.
- **MSO `x5chain` / SD-JWT `x5c` chain validation**: not wired (see section 5.4).

### 5.7 Wallet-instance attestation

Wired in `LocalPackages/WalletCore/Sources/WalletEngine/Kit/WalletKitConfig.swift` lines 33-37 as `KeyAttestationConfiguration`, implemented by `DefaultWalletAttestationsProvider`.
Wallet Provider base URL is hard-coded `https://wallet-provider.eudiw.dev` (the EU reference provider).
On demand the SDK calls:

- `getWalletAttestation(key:)` → `POST /wallet-instance-attestation/jwk` with the wallet's JWK.
- `getKeysAttestation(keys:nonce:)` → `POST /wallet-unit-attestation/jwk-set`.

The wallet key is generated and held inside EudiWalletKit (Secure Enclave by default).

### 5.8 Status list and revocation

`statusListURI` and `statusListIdx` are read from each issued credential and passed to EudiWalletKit's `wallet.getDocumentStatus(for:)` in `LocalPackages/WalletCore/Sources/WalletEngine/Kit/WalletKitController.swift` lines 339–367 (`checkDocumentStatus`).
EudiWalletKit's Statium component performs the HTTP GET, decodes the Token Status List JWT, and returns the document state.
The wallet does not pin a status-list signer; trust of the status-list JWT signature is delegated entirely to Statium.

Periodic polling lives in `LocalPackages/WalletCore/Sources/WalletCore/Controller/DocumentRevocationService.swift`.
Current values are 10 s interval and 5 s initial delay (QA values).
Production targets are 300 s and 30 s respectively, per inline TODOs at lines 26-31.

### 5.9 Per-environment configuration swap

To target a different environment (e.g. staging vs production):

1. Edit `wallet-config.json` to list the desired issuer hosts, priorities, and per-issuer `metadataTrustRoots`.
2. Update `verifierReaderTrustRoots` to the desired set.
3. Ensure every referenced `.der` basename exists under `DiiaGovStackWallet/Common/Wallet/Certificates/`.
4. Rebuild and verify trust-root loading in logs (look for `[E2E][TrustStore]` entries; any `❌` indicates a missing or malformed file).

There is no compile-time switch between environments; the wallet ships exactly the JSON content checked in.

### 5.10 Verification Checklist

Run through this before promoting a build past internal testers.

- [ ] `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` are bumped to values not yet uploaded to App Store Connect.
- [ ] Release scheme builds with `Manual` code signing, identity `iPhone Distribution`, team `<TEAM_ID_RELEASE>`, profile `Diia_GovStack_Wallet_distribution`.
- [ ] Archive bundle ID is `ua.govstack.digitalwallet.app.dev`.
- [ ] `wallet-config.json` lists the intended issuer hosts for the target environment.
- [ ] Every `metadataTrustRoots` and `verifierReaderTrustRoots` entry resolves to a real file under `DiiaGovStackWallet/Common/Wallet/Certificates/`.
- [ ] No `[E2E][TrustStore] ❌` entries appear in launch logs.
- [ ] App launches without hitting any `fatalError` in `AppConfigurator.bootstrapWalletConfiguration`.
- [ ] Issuer picker shows issuers in the expected order (`displayPriority` descending).
- [ ] OID4VCI flow completes against each configured issuer.
- [ ] OID4VP presentation against a verifier whose reader-auth cert chains to a configured root succeeds.
- [ ] Verifier reader-auth gate behaviour matches policy (lenient `!= false`); has not been flipped.
- [ ] dSYMs are present in the archive bundle for crash symbolication.
- [ ] Build appears in TestFlight with status "Ready to Test" and is assigned to the right tester groups.
