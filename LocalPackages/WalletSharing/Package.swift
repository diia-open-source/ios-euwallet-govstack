// swift-tools-version: 5.8

import PackageDescription

let package = Package(
    name: "WalletSharing",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "WalletSharing",
            targets: ["WalletSharing"]
        ),
    ],
    dependencies: [
        .package(path: "../ios-mvpmodule"),
        .package(url: "https://github.com/airbnb/lottie-spm.git", exact: Version(4, 6, 0)),
        .package(path: "../commontypes"),
        .package(path: "../core-common-services"),
        .package(path: "../ios-core-uicomponents"),
        .package(path: "../WalletAuthorization"),
        .package(path: "../WalletDocuments"),
        .package(path: "../WalletCore"),
    ],
    targets: [
        .target(
            name: "WalletSharing",
            dependencies: [
                .product(name: "DiiaMVPModule", package: "ios-mvpmodule"),
                .product(name: "DiiaCommonTypes", package: "commontypes"),
                .product(name: "DiiaCommonServices", package: "core-common-services"),
                .product(name: "DiiaUIComponents", package: "ios-core-uicomponents"),
                .product(name: "WalletAuthorizationPinCode", package: "WalletAuthorization"),
                .product(name: "WalletDocumentsCore", package: "WalletDocuments"),
                .product(name: "Lottie", package: "lottie-spm"),
                .product(name: "WalletDomainModels", package: "WalletCore"),
                .product(name: "WalletCore", package: "WalletCore"),
            ],
            path: "Sources/WalletSharing"
        ),
    ]
)
