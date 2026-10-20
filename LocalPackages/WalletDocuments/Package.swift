// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WalletDocuments",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "WalletDocumentsCommonTypes",
            targets: ["WalletDocumentsCommonTypes"]),
        .library(
            name: "WalletDocumentsCore",
            targets: ["WalletDocumentsCore"]),
    ],
    dependencies: [
        .package(url: "https://github.com/DeclarativeHub/ReactiveKit.git", .upToNextMinor(from: "3.16.2")),
        .package(url: "https://github.com/airbnb/lottie-spm.git", exact: Version(4, 6, 0)),
        .package(path: "../ios-mvpmodule"),
        .package(path: "../commontypes"),
        .package(path: "../core-common-services"),
        .package(path: "../ios-core-uicomponents"),
    ],
    targets: [
        .target(
            name: "WalletDocumentsCommonTypes",
            dependencies: [
                "ReactiveKit",
                .product(name: "DiiaCommonTypes", package: "commontypes"),
                .product(name: "DiiaUIComponents", package: "ios-core-uicomponents"),
                .product(name: "Lottie", package: "lottie-spm"),
            ],
            path: "Sources/WalletDocumentsCommonTypes",
            resources: [.process("Resources/Animations")]
        ),
        .target(
            name: "WalletDocumentsCore",
            dependencies: [
                .product(name: "DiiaMVPModule", package: "ios-mvpmodule"),
                .product(name: "DiiaCommonTypes", package: "commontypes"),
                .product(name: "DiiaUIComponents", package: "ios-core-uicomponents"),
                .product(name: "DiiaCommonServices", package: "core-common-services"),
                .product(name: "Lottie", package: "lottie-spm"),
                "WalletDocumentsCommonTypes",
            ],
            path: "Sources/WalletDocumentsCore",
            resources: [.process("Resources/Animations")]
        ),
    ]
)
