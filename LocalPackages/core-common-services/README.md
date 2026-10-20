# DiiaCommonServices

CoreCommonServices is a foundational utilities and modules providing essential support for Diia on iOS.

## Description

### Helping modules

* `GeneralError`: _Provides generalized error handling mechanisms for advanced error management._
* `BaseSearch`: _Provides a standardized basis for easy integration of search functionalities._
* `ContactsInput`: _Provides a generalized foundation for handling user inputs in tasks related to contacts._
* `TemplateAlert`: _Provides alert templates for a consistent visual messaging style across the app._

### Utility

* `ReachabilityHelper`

## Useful Links

|Topic|Link|Description|
|--|--|--|
|Ministry of Digital Transformation of Ukraine|https://thedigital.gov.ua/|The Official homepage of the Ministry of Digital Transformation of Ukraine|
|Diia App|https://diia.gov.ua/|The Official website for the Diia application|

## Getting Started

### Installing

This package lives in the wallet repository and is consumed locally via a path dependency:

```swift
.package(path: "../core-common-services")
```

The upstream version is published at [diia-open-source/ios-commonservices](https://github.com/diia-open-source/ios-commonservices).

## Code Verification

### Swiftlint

This package follows the wallet project's SwiftLint configuration; the host enforces lint at build time.

## Modifications in this fork

In-tree fork of [`diia-open-source/ios-commonservices`](https://github.com/diia-open-source/ios-commonservices), maintained independently of upstream. The most notable difference:

- **No `DiiaNetwork` (`ios-network`) dependency.** The wallet does not route credential traffic through the original Diia network layer, so the upstream `ios-network` dep is absent. `GeneralError` is constructed directly rather than from a `NetworkError`; the `GeneralErrorViewModel.init(networkError:)` initialiser is absent for the same reason.

Further wallet-side adjustments are tracked via the wallet repository's git history.

## How to contribute

This in-tree copy is maintained as part of the wallet project; contributions follow the wallet repository's contribution guidelines.

## Licensing

Copyright (C) Diia and all other contributors.

Licensed under the **EUPL** (the "License"); you may not use this file except in compliance with the License. Re-use is permitted, although not encouraged, under the EUPL, with the exception of source files that contain a different license.

You may obtain a copy of the License in the [`LICENSE.md`](LICENSE.md) file and at [https://joinup.ec.europa.eu/collection/eupl/eupl-text-eupl-12](https://joinup.ec.europa.eu/collection/eupl/eupl-text-eupl-12).
