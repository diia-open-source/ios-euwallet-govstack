# DiiaMVPModule

Model-View-Presenter basic protocols.

## Description

* `BaseModule`: _Defines module structure and provides a view controller._
* `BasePresenter`: _Facilitates model-view interaction and configures the associated view._
* `BaseView`: _Manages seamless module navigation and presentation in the MVP architecture. Provides UI-related functionalities: progress handling, error and message display._

## Useful Links

|Topic|Link|Description|
|--|--|--|
|Ministry of Digital Transformation of Ukraine|https://thedigital.gov.ua/|The Official homepage of the Ministry of Digital Transformation of Ukraine|
|Diia App|https://diia.gov.ua/|The Official website for the Diia application|

## Getting Started

### Installing

This package lives in the wallet repository and is consumed locally via a path dependency:

```swift
.package(path: "../ios-mvpmodule")
```

The upstream version is published at [diia-open-source/ios-mvpmodule](https://github.com/diia-open-source/ios-mvpmodule).

## Code Verification

### Swiftlint

This package follows the wallet project's SwiftLint configuration; the host enforces lint at build time.

## Modifications in this fork

In-tree fork of [`diia-open-source/ios-mvpmodule`](https://github.com/diia-open-source/ios-mvpmodule), maintained independently of upstream. Wallet-side adjustments are tracked via the wallet repository's git history.

## How to contribute

This in-tree copy is maintained as part of the wallet project; contributions follow the wallet repository's contribution guidelines.

## Licensing

Copyright (C) Diia and all other contributors.

Licensed under the **EUPL** (the "License"); you may not use this file except in compliance with the License. Re-use is permitted, although not encouraged, under the EUPL, with the exception of source files that contain a different license.

You may obtain a copy of the License in the [`LICENSE.md`](LICENSE.md) file and at [https://joinup.ec.europa.eu/collection/eupl/eupl-text-eupl-12](https://joinup.ec.europa.eu/collection/eupl/eupl-text-eupl-12).
