// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "test",
    platforms: [
        .iOS(.v9),
        .macOS(.v10_10),
        .watchOS(.v3),
        .tvOS(.v9)
    ],
    dependencies: [
        // for testing from same repository
        .package(path: "../..")
        // normally this would be:
        // .package(url: "https://github.com/stephencelis/SQLite.swift.git", from: "0.13.0")
    ],
    targets: [
        .target(
            name: "test",
            dependencies: [.product(name: "SQLite", package: "SQLite.swift")]
	)
    ]
)
