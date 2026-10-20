// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WalletAuthorization",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "WalletAuthorization",
            targets: ["WalletAuthorization"]),
        .library(
            name: "WalletAuthorizationPinCode",
            targets: ["WalletAuthorizationPinCode"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/DeclarativeHub/ReactiveKit.git", from: "3.16.2"),
        .package(path: "../ios-mvpmodule"),
        .package(path: "../commontypes"),
        .package(path: "../core-common-services"),
        .package(path: "../ios-core-uicomponents"),
        .package(path: "../WalletAppStorage"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "WalletAuthorization",
            dependencies: [
                .product(name: "DiiaMVPModule", package: "ios-mvpmodule"),
                .product(name: "DiiaCommonTypes", package: "commontypes"),
                .product(name: "DiiaUIComponents", package: "ios-core-uicomponents"),
                .product(name: "DiiaCommonServices", package: "core-common-services"),
                .product(name: "WalletAppStorage", package: "WalletAppStorage"),
                "ReactiveKit",
        	],
        	path: "Sources/WalletAuthorization"
        ),
        .target(
            name: "WalletAuthorizationPinCode",
            dependencies: [
                .product(name: "DiiaMVPModule", package: "ios-mvpmodule"),
                .product(name: "DiiaUIComponents", package: "ios-core-uicomponents"),
                .product(name: "DiiaCommonTypes", package: "commontypes"),
                .product(name: "WalletAppStorage", package: "WalletAppStorage"),
                "WalletAuthorization",
            ],
            path: "Sources/WalletAuthorizationPinCode"
        ),
    ]
)
