// swift-tools-version: 5.8

import PackageDescription

let package = Package(
    name: "WalletIssuing",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "WalletIssuing",
            targets: ["WalletIssuing"]
        ),
    ],
    dependencies: [
        .package(path: "../ios-mvpmodule"),
        .package(path: "../commontypes"),
        .package(path: "../core-common-services"),
        .package(path: "../ios-core-uicomponents"),
        .package(path: "../WalletContextMenu"),
        .package(path: "../WalletDocuments"),
        .package(path: "../WalletCore"),
    ],
    targets: [
        .target(
            name: "WalletIssuing",
            dependencies: [
                .product(name: "DiiaMVPModule", package: "ios-mvpmodule"),
                .product(name: "DiiaCommonTypes", package: "commontypes"),
                .product(name: "DiiaCommonServices", package: "core-common-services"),
                .product(name: "DiiaUIComponents", package: "ios-core-uicomponents"),
                .product(name: "WalletContextMenu", package: "WalletContextMenu"),
                .product(name: "WalletDocumentsCore", package: "WalletDocuments"),
                .product(name: "WalletDocumentsCommonTypes", package: "WalletDocuments"),
                .product(name: "WalletDomainModels", package: "WalletCore"),
                .product(name: "WalletCore", package: "WalletCore"),
            ],
            path: "Sources/WalletIssuing"
        ),
    ]
)
