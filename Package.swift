// swift-tools-version: 6.1
import PackageDescription
let applePlatforms: [PackageDescription.Platform] = [.iOS, .macOS, .watchOS, .tvOS, .visionOS]

let target: Target = .target(
    name: "SQLite",
    dependencies: [
        .product(name: "SwiftToolchainCSQLite",
                 package: "swift-toolchain-sqlite",
                 condition: .when(traits: ["SwiftToolchainCSQLite"])),
        .product(name: "SQLiteSwiftCSQLite",
                 package: "CSQLite",
                 condition: .when(traits: ["SQLiteSwiftCSQLite"])),
        .product(name: "SQLCipher",
                 package: "SQLCipher.swift",
                 condition: .when(platforms: applePlatforms, traits: ["SQLCipher"]))
    ],
    exclude: ["Info.plist"],
    resources: [.copy("PrivacyInfo.xcprivacy")],
    cSettings: [
        .define("SQLITE_HAS_CODEC", .when(platforms: applePlatforms, traits: ["SQLCipher"]))
    ]
)

let testTarget: Target = .testTarget(
    name: "SQLiteTests",
    dependencies: ["SQLite"],
    exclude: ["Info.plist"],
    resources: [.copy("Resources")]
)

let defaultTraits: Set<String>
#if os(Linux)
defaultTraits = ["SwiftToolchainCSQLite"]
#else
defaultTraits = ["SystemSQLite"]
#endif

let package = Package(
    name: "SQLite.swift",
    platforms: [
        .iOS(.v12),
        .macOS(.v10_13),
        .watchOS(.v4),
        .tvOS(.v12),
        .visionOS(.v1)
    ],
    products: [
        .library(name: "SQLite", targets: ["SQLite"]),
        .library(name: "SQLite-Dynamic", type: .dynamic, targets: ["SQLite"])
    ],
    traits: [
        .trait(name: "SystemSQLite",
              description: "Uses the system-provided SQLite (on Apple platforms)"),
        .trait(name: "SwiftToolchainCSQLite",
               description: "Include SQLite from the Swift toolchain"),
        .trait(name: "SQLiteSwiftCSQLite",
               description: "Include SQLite from SQLite.swift, based on the toolchain version"),
        // this will note compile, just included for sake of completeness
        .trait(name: "StandaloneSQLite",
               description: "Assumes SQLite to be already available as 'sqlite3'"),
        .trait(name: "SQLCipher",
               description: "Enables SQLCipher encryption when a key is supplied to Connection"),
        .trait(name: "FTS5",
              description: "Enables FTS5 in the embedded SQLite (only supported by SQLiteSwiftCSQLite)"),
        .default(enabledTraits: defaultTraits)
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-toolchain-sqlite", from: "1.0.7"),
        .package(url: "https://github.com/stephencelis/CSQLite", from: "3.50.4", traits: [.trait(name: "FTS5", condition: .when(traits: ["FTS5"]))]),
        .package(url: "https://github.com/sqlcipher/SQLCipher.swift", from: "4.11.0")
    ],
    targets: [target, testTarget],
    swiftLanguageModes: [.v5],
)
