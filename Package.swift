// swift-tools-version: 6.1
import PackageDescription
let applePlatforms: [PackageDescription.Platform] = [.iOS, .macOS, .watchOS, .tvOS, .visionOS]

// Package.swift always compiles for the host, so it can't see the build
// destination directly — an environment variable (matching the convention
// used by swift-android-native's own `TARGET_OS_ANDROID` check) is the only
// way to detect an Android cross-compile here. `PrivacyInfo.xcprivacy` is
// only meaningful for the Apple App Store; declaring it as a resource makes
// SwiftPM generate a `Bundle.module` accessor that requires linking all of
// Foundation on Android, so it's excluded there.
let isAndroid = Context.environment["TARGET_OS_ANDROID"] ?? "0" != "0"

let target: Target = .target(
    name: "SQLite",
    dependencies: [
        .product(name: "SQLiteSwiftCSQLite",
                 package: "CSQLite",
                 condition: .when(traits: ["SQLiteSwiftCSQLite"])),
        .product(name: "SQLCipher",
                 package: "SQLCipher.swift",
                 condition: .when(platforms: applePlatforms, traits: ["SQLCipher"]))
    ],
    exclude: isAndroid ? ["Info.plist", "PrivacyInfo.xcprivacy"] : ["Info.plist"],
    resources: isAndroid ? [] : [.copy("PrivacyInfo.xcprivacy")],
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
defaultTraits = ["SQLiteSwiftCSQLite"]
#else
defaultTraits = ["SystemSQLite"]
#endif

let package = Package(
    name: "SQLite.swift",
    platforms: [
        .iOS(.v12),
        .macOS(.v10_13),
        .watchOS(.v9),
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
        .package(url: "https://github.com/stephencelis/CSQLite", from: "3.50.4", traits: [.trait(name: "FTS5", condition: .when(traits: ["FTS5"]))]),
        .package(url: "https://github.com/sqlcipher/SQLCipher.swift", from: "4.11.0")
    ],
    targets: [target, testTarget],
    swiftLanguageModes: [.v5],
)
