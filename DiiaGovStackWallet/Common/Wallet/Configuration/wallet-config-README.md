# Wallet Configuration

This folder is the **single source of truth** for which OID4VCI issuers the wallet talks to, which X.509 roots it trusts, and the deployment's own wallet-provider and OID4VCI client identity.

To add/change/remove an issuer or a trust root, you should only need to touch the files in this folder and (for new certs) the sibling `../Certificates/` folder.
No Swift code changes required.

## Files

- `wallet-config.json` — the config itself (issuers, trust roots, and the wallet provider / client identity).
- `WalletConfiguration.swift` — Codable loader.
  Loaded once at app launch via `WalletConfiguration.shared`.
  Fail-fast: a missing or malformed `wallet-config.json` is a `fatalError`, not a silent degradation.
- `../Certificates/*.der` — DER-encoded trust roots referenced by name from the JSON.

## Schema

```json
{
  "issuers": [
    {
      "host": "issuer.example.com",
      "displayPriority": 2,
      "metadataTrustRoots": ["some_ca"]
    }
  ],
  "verifierReaderTrustRoots": ["some_ca", "another_ca"],
  "walletProviderBaseURL": "https://wallet-provider.example.com",
  "clientId": "your-wallet-client-id",
  "authFlowRedirectionURI": "your-wallet-scheme://authorization"
}
```

### `issuers[]`

| Field | Type | Meaning |
|---|---|---|
| `host` | string | The issuer's hostname (no scheme). Used as the credential issuer URL (`https://<host>`) and as the lookup key throughout the app. |
| `displayPriority` | int | Sort order in the "Add document" picker. Higher = earlier. Ties break by document-type priority, then by name. |
| `metadataTrustRoots` | string[] | Cert filenames (without `.der`) that are accepted as trust anchors when validating this issuer's OID4VCI metadata JWT. Scoped per-issuer so a self-signed cert from one issuer cannot vouch for another. Empty list = no signed-metadata validation possible (only plain-JSON metadata responses will be accepted). |

### `verifierReaderTrustRoots`

Cert filenames (without `.der`) accepted as trust anchors for **verifier reader-auth** certificates during BLE / OpenID4VP presentations.

This is the *verifier* side, not the issuer side — these roots authorise apps that scan your wallet, not apps that issue credentials to it.

The bb-wallet-issuer self-signed cert is intentionally **NOT** in this list — it's a metadata-signing key, not a verifier CA.

### Wallet provider & OID4VCI client

These three are the deployment's **own identity** — each deployment must set its own.
The wallet no longer falls back to the EUDI reference values, so a missing key (or a malformed `walletProviderBaseURL`) is a `fatalError` at launch, the same fail-fast policy as the rest of the config.

| Field | Type | Meaning |
|---|---|---|
| `walletProviderBaseURL` | string (URL) | Base URL of the wallet-provider backend that issues the wallet's key attestations. Must be a valid absolute URL. |
| `clientId` | string | The OID4VCI `client_id` the wallet presents to issuers during the authorization-code flow. |
| `authFlowRedirectionURI` | string (URI) | The redirect URI the wallet registers for that flow; the issuer redirects the user back here after authorization, and the in-app web-auth session captures it by scheme. |

## How to...

### Add a new issuer

1. Append an object to the `issuers` array in `wallet-config.json`.
2. If the issuer signs its metadata, drop the signing root as `<name>.der` into `../Certificates/` and reference `<name>` (no extension) in `metadataTrustRoots`.
3. Build. Done.

### Add a new trusted certificate

1. Drop `<name>.der` into `../Certificates/`.
2. Reference `<name>` (no extension) in the appropriate bucket — `metadataTrustRoots` (per-issuer) or `verifierReaderTrustRoots` (global).
3. Build. Done.

### Remove a trusted certificate

1. Remove every reference to its name from `wallet-config.json`.
2. Delete the `.der` from `../Certificates/`.

### Change picker order

Adjust `displayPriority` integers. Higher number = earlier in the list.

### Point the wallet at your provider / set its client identity

Set `walletProviderBaseURL`, `clientId`, and `authFlowRedirectionURI` to your deployment's values in `wallet-config.json`.
They are required — the wallet won't start without them, and it won't fall back to the reference `eudiw.dev` / `wallet-dev` values.

## Trust-bucket cheat sheet

| Bucket | Validates | Scope |
|---|---|---|
| `metadataTrustRoots` | OID4VCI metadata JWT (`x5c` header) | Per-issuer |
| `verifierReaderTrustRoots` | Verifier reader-auth cert (mDL presentation flow) | Global |

A future third bucket — `trustedIssuerCertificates` — is planned for MSO `x5chain` / SD-JWT VC `x5c` validation, but is blocked on an upstream EudiWalletKit fix (see TODO in `EudiWalletKitConfig.swift`).

## Xcode target membership

`wallet-config.json` and `WalletConfiguration.swift` **must** be members of the `DiiaGovStackWallet` target.
Without that, the JSON won't ship in the bundle and `WalletConfiguration.shared` will `fatalError` at launch with `wallet-config.json not found in bundle`.
Same for any new `.der` you add to `../Certificates/`.
