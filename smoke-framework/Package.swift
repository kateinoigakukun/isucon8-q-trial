// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "isucon8",
    platforms: [
        .macOS(.v10_15)
    ],
    dependencies: [
        .package(url: "https://github.com/amzn/smoke-framework.git", from: "2.9.0")
    ],
    targets: [
        .target(
            name: "isucon8",
            dependencies: [
                .product(name: "SmokeOperationsHTTP1Server", package: "smoke-framework"),
            ]),
    ]
)
