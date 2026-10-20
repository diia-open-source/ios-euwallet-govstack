// swift-tools-version: 5.8

import PackageDescription

let package = Package(
    name: "WalletGallery",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "WalletGallery",
            targets: ["WalletGallery"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/DeclarativeHub/ReactiveKit.git", from: "3.16.2"),
        .package(path: "../ios-mvpmodule"),
        .package(path: "../commontypes"),
        .package(path: "../ios-core-uicomponents"),
        .package(path: "../WalletDocuments"),
        .package(path: "../WalletAppStorage"),
        .package(path: "../WalletCore"),
    ],
    targets: [
        .target(
            name: "WalletGallery",
            dependencies: [
                "ReactiveKit",
                .product(name: "DiiaMVPModule", package: "ios-mvpmodule"),
                .product(name: "DiiaCommonTypes", package: "commontypes"),
                .product(name: "DiiaUIComponents", package: "ios-core-uicomponents"),
                .product(name: "WalletDocumentsCore", package: "WalletDocuments"),
                .product(name: "WalletDocumentsCommonTypes", package: "WalletDocuments"),
                .product(name: "WalletAppStorage", package: "WalletAppStorage"),
                .product(name: "WalletDomainModels", package: "WalletCore"),
                .product(name: "WalletCore", package: "WalletCore"),
            ],
            path: "Sources/WalletGallery"
        ),
    ]
)
