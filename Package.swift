// swift-tools-version:4.2
import PackageDescription

let package = Package(
    name: "SQLite",
    // platforms: [.iOS("8.0"), .macOS("10.10"), tvOS("9.1"), .watchOS("2.0")],
    products: [
        .library(name: "SQLite", targets: ["SQLite"])
    ],
    targets: [
        .target(
            name: "SQLite",
            dependencies: ["SQLiteObjc"],
            path: "Sources/SQLite"
        ),
        .target(
            name: "SQLiteObjc",
            path: "Sources/SQLiteObjc"
        ),
        .testTarget(
            name: "SQLiteTests", 
            dependencies: ["SQLite"], 
            path: "Tests/SQLiteTests"
        )
    ]
)

#if os(Linux)
    package.dependencies = [.package(url: "https://github.com/stephencelis/CSQLite.git", from: "0.0.3")]
    package.targets = [
        .target(name: "SQLite", exclude: ["Extensions/FTS4.swift", "Extensions/FTS5.swift"]),
        .testTarget(name: "SQLiteTests", dependencies: ["SQLite"], path: "Tests/SQLiteTests", exclude: [
            "FTS4Tests.swift",
            "FTS5Tests.swift"
        ])
    ]
#endif
