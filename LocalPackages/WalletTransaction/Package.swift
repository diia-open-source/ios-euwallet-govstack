// swift-tools-version: 5.8

import PackageDescription

let package = Package(
    name: "WalletTransaction",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "WalletTransaction",
            targets: ["WalletTransaction"]
        ),
    ],
    dependencies: [
        .package(path: "../ios-mvpmodule"),
        .package(path: "../commontypes"),
        .package(path: "../core-common-services"),
        .package(path: "../ios-core-uicomponents"),
        .package(path: "../WalletCore"),
    ],
    targets: [
        .target(
            name: "WalletTransaction",
            dependencies: [
                .product(name: "DiiaMVPModule", package: "ios-mvpmodule"),
                .product(name: "DiiaCommonTypes", package: "commontypes"),
                .product(name: "DiiaCommonServices", package: "core-common-services"),
                .product(name: "DiiaUIComponents", package: "ios-core-uicomponents"),
                .product(name: "WalletDomainModels", package: "WalletCore"),
                .product(name: "WalletCore", package: "WalletCore"),
            ],
            path: "Sources/WalletTransaction"
        ),
    ]
)
