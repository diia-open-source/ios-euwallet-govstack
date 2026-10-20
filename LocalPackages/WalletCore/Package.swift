// swift-tools-version: 5.8

import PackageDescription

let package = Package(
    name: "WalletCore",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "WalletDomainModels",
            targets: ["WalletDomainModels"]
        ),
        .library(
            name: "WalletCore",
            targets: ["WalletCore"]
        ),
        .library(
            name: "WalletEngine",
            targets: ["WalletEngine"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/eu-digital-identity-wallet/eudi-lib-ios-wallet-kit.git", exact: "0.30.1"),
        .package(url: "https://github.com/airsidemobile/JOSESwift.git", from: "3.0.0"),
        .package(path: "../ios-mvpmodule"),
        .package(path: "../commontypes"),
        .package(path: "../WalletDocuments"),
    ],
    targets: [
        .target(
            name: "WalletDomainModels",
            dependencies: [
                .product(name: "DiiaCommonTypes", package: "commontypes"),
                // Needed by Models/DocType.swift for DocumentAttributesProtocol / DocTypeCode / WarningModel / DocumentStackIconAppearance.
                // Roadmap §1 envisioned this target as DiiaCommonTypes-only, but DocType's conformance to DocumentAttributesProtocol pulls this in; pragmatic deviation rather than ripping the conformance out.
                .product(name: "WalletDocumentsCommonTypes", package: "WalletDocuments"),
            ],
            path: "Sources/WalletDomainModels"
        ),
        .target(
            name: "WalletCore",
            dependencies: [
                "WalletDomainModels",
                .product(name: "DiiaCommonTypes", package: "commontypes"),
                .product(name: "DiiaMVPModule", package: "ios-mvpmodule"),
            ],
            path: "Sources/WalletCore"
        ),
        .target(
            name: "WalletEngine",
            dependencies: [
                "WalletDomainModels",
                "WalletCore",
                .product(name: "EudiWalletKit", package: "eudi-lib-ios-wallet-kit"),
                "JOSESwift",
            ],
            path: "Sources/WalletEngine"
        ),
    ]
)
