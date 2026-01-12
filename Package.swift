// swift-tools-version: 6.1
import PackageDescription

let deps: [Package.Dependency] = [
    .package(url: "https://github.com/swiftlang/swift-toolchain-sqlite", from: "1.0.7"),
    .package(url: "https://github.com/sqlcipher/SQLCipher.swift.git", from: "4.11.0")
]

let applePlatforms: [PackageDescription.Platform] = [.iOS, .macOS, .watchOS, .tvOS, .visionOS]
let sqlcipherTraitBuildSettingCondition: BuildSettingCondition? = .when(platforms: applePlatforms, traits: ["SQLCipher"])
let cSettings: [CSetting] = [.define("SQLITE_HAS_CODEC", to: nil, sqlcipherTraitBuildSettingCondition)]

let targets: [Target] = [
    .target(
        name: "SQLite",
        dependencies: [
            .product(name: "SwiftToolchainCSQLite", package: "swift-toolchain-sqlite", condition: .when(platforms: [.linux, .windows, .android])),
            .product(name: "SQLCipher", package: "SQLCipher.swift", condition: .when(platforms: applePlatforms, traits: ["SQLCipher"]))
        ],
        exclude: ["Info.plist"],
        cSettings: cSettings
    )
]

let testTargets: [Target] = [
    .testTarget(
        name: "SQLiteTests",
        dependencies: ["SQLite"],
        path: "Tests/SQLiteTests",
        exclude: ["Info.plist"],
        resources: [.copy("Resources")]
    )
]

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
        .library(
            name: "SQLite",
            targets: ["SQLite"]
        )
    ],
    traits: [
        .trait(name: "SQLCipher", description: "Enables SQLCipher encryption when a key is supplied to Connection")
    ],
    dependencies: deps,
    targets: targets + testTargets,
    swiftLanguageModes: [.v5],
)
