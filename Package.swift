// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "SQLite.swift",
    platforms: [.macOS(.v11)],
    products: [
        .library(
            name: "SQLiteSwift",
            targets: ["SQLiteSwift"]
        )
    ],
    targets: [
        .target(
            name: "SQLiteSwift",
            path: "Sources/SQLite",
            exclude: [
                "Info.plist"
            ],
            resources: [
                .copy("PrivacyInfo.xcprivacy")
            ]
        ),
        .testTarget(
            name: "SQLiteTests",
            dependencies: [
                "SQLiteSwift"
            ],
            path: "Tests/SQLiteTests",
            exclude: [
                "Info.plist"
            ],
            resources: [
                .copy("Resources")
            ]
        )
    ]
)

// Use CSQLite on all platforms to ensure consistent SQLite configuration
// (especially SQLITE_MAX_VARIABLE_NUMBER for Timing's long filter queries)
package.dependencies = [
    .package(url: "https://github.com/Timing-GmbH/CSQLite", branch: "main")
]
package.targets.first?.dependencies += [
    .product(name: "CSQLite", package: "CSQLite")
]
