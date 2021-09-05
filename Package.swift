// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "SQLite.swift",
    products: [
        .library(
            name: "SQLite",
            targets: ["SQLite"]
        )
    ],
    targets: [
        .target(
            name: "SQLite",
            dependencies: ["SQLiteObjc"],
            exclude: [
                "Info.plist"
            ]
        ),
        .target(
            name: "SQLiteObjc",
            dependencies: [],
            exclude: [
                "fts3_tokenizer.h"
            ]
        ),
        .testTarget(
            name: "SQLiteTests",
            dependencies: [
                "SQLite"
            ],
            path: "Tests/SQLiteTests",
            exclude: [
                "Info.plist"
            ],
            resources: [
                .copy("fixtures/encrypted-3.x.sqlite"),
                .copy("fixtures/encrypted-4.x.sqlite")
            ]
        )
    ]
)

#if os(Linux)
package.dependencies = [.package(url: "https://github.com/stephencelis/CSQLite.git", from: "0.0.3")]
package.targets = [
    .target(
        name: "SQLite",
        dependencies: [.product(name: "CSQLite", package: "CSQLite")],
        exclude: ["Extensions/FTS4.swift", "Extensions/FTS5.swift"]
    ),
    .testTarget(name: "SQLiteTests", dependencies: ["SQLite"], path: "Tests/SQLiteTests", exclude: [
        "FTSIntegrationTests.swift",
        "FTS4Tests.swift",
        "FTS5Tests.swift"
    ])
]
#endif
