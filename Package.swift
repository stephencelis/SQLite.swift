// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "SQLite.swift",
    products: [.library(name: "SQLite", targets: ["SQLite"])],
    targets: [
        .target(name: "SQLite", dependencies: ["SQLiteObjc"]),
        .target(name: "SQLiteObjc"),
        .testTarget(name: "SQLiteTests", dependencies: ["SQLite"], path: "Tests/SQLiteTests")
    ],
    swiftLanguageVersions: [4]
)
