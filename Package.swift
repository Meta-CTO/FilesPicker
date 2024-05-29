// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FilesPicker",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        .library(
            name: "FilesPicker",
            targets: ["FilesPicker"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/guoyingtao/Mantis", exact: "2.21.0")
    ],
    targets: [
        .target(
            name: "FilesPicker",
            dependencies: [
                .product(name: "Mantis", package: "Mantis")
            ]
        )
    ]
)
