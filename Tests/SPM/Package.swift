// swift-tools-version:6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let traits: Set<Package.Dependency.Trait>
#if os(Linux)
traits = ["SwiftToolchainCSQLite"]
#else
traits = [.defaults]
#endif

let package = Package(
    name: "test",
    platforms: [
        .iOS(.v12),
        .macOS(.v10_13),
        .watchOS(.v4),
        .tvOS(.v12)
    ],
    dependencies: [
        // for testing from same repository
        .package(path: "../..", traits: traits)
        // normally this would be:
        // .package(url: "https://github.com/stephencelis/SQLite.swift.git", from: "0.15.4")
    ],
    targets: [
        .executableTarget(name: "test", dependencies: [.product(name: "SQLite", package: "SQLite.swift")])
    ]
)
