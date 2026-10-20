// swift-tools-version: 5.8

import PackageDescription

let package = Package(
    name: "WalletAppStorage",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "WalletAppStorage",
            targets: ["WalletAppStorage"]
        ),
    ],
    dependencies: [
        .package(path: "../commontypes"),
        .package(url: "https://github.com/groue/GRDB.swift.git", .upToNextMinor(from: "7.10.0")),
        .package(path: "../WalletCore"),
    ],
    targets: [
        .target(
            name: "WalletAppStorage",
            dependencies: [
                .product(name: "DiiaCommonTypes", package: "commontypes"),
                .product(name: "GRDB", package: "GRDB.swift"),
                .product(name: "WalletCore", package: "WalletCore"),
                .product(name: "WalletDomainModels", package: "WalletCore"),
            ],
            path: "Sources/WalletAppStorage"
        ),
    ]
)
