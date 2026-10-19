// swift-tools-version:6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "test",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .watchOS(.v9),
        .tvOS(.v12)
    ],
    dependencies: [
        // for testing from same repository
        .package(path: "../..", traits: [])
        // normally this would be:
        // .package(url: "https://github.com/stephencelis/SQLite.swift.git", from: "0.16.0")
    ],
    targets: [
        .executableTarget(name: "test", dependencies: [.product(name: "SQLite", package: "SQLite.swift")])
    ]
)
