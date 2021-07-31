// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "isucon8",
    platforms: [
       .macOS(.v10_15)
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", .branch("async-await")),
        .package(url: "https://github.com/vapor/mysql-kit.git", from: "4.0.0"),
    ],
    targets: [
        .target(
            name: "App",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                .product(name: "MySQLKit", package: "mysql-kit")
            ],
            swiftSettings: [
                // Enable better optimizations when building in Release configuration. Despite the use of
                // the `.unsafeFlags` construct required by SwiftPM, this flag is recommended for Release
                // builds. See <https://github.com/swift-server/guides/blob/main/docs/building.md#building-for-production> for details.
                .unsafeFlags(["-cross-module-optimization"], .when(configuration: .release)),
                // Disable availability checking to use concurrency API on macOS for development purpose
                // SwiftNIO exposes concurrency API with availability for deployment environment,
                // but in our use case, the deployment target is Linux, and we only use macOS while development,
                // so it's always safe to disable the checking in this situation.
                .unsafeFlags(["-Xfrontend", "-disable-availability-checking"])
            ]
        ),
        .target(name: "Run", dependencies: [.target(name: "App")]),
        .testTarget(name: "AppTests", dependencies: [
            .target(name: "App"),
            .product(name: "XCTVapor", package: "vapor"),
        ])
    ]
)
