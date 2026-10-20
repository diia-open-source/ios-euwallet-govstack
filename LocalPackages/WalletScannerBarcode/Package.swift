// swift-tools-version: 5.8

import PackageDescription

let package = Package(
    name: "WalletScannerBarcode",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "WalletScannerBarcode",
            targets: ["WalletScannerBarcode"]
        ),
    ],
    dependencies: [
        .package(path: "../ios-mvpmodule"),
        .package(path: "../commontypes"),
        .package(path: "../ios-core-uicomponents"),
        .package(path: "../WalletCore"),
    ],
    targets: [
        .target(
            name: "WalletScannerBarcode",
            dependencies: [
                .product(name: "DiiaMVPModule", package: "ios-mvpmodule"),
                .product(name: "DiiaCommonTypes", package: "commontypes"),
                .product(name: "DiiaUIComponents", package: "ios-core-uicomponents"),
                .product(name: "WalletDomainModels", package: "WalletCore"),
                .product(name: "WalletCore", package: "WalletCore"),
            ],
            path: "Sources/WalletScannerBarcode"
        ),
    ]
)
