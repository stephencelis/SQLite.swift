// swift-tools-version: 6.1
import PackageDescription
let applePlatforms: [PackageDescription.Platform] = [.iOS, .macOS, .watchOS, .tvOS, .visionOS]

let target: Target = .target(
    name: "SQLite",
    dependencies: [
        .product(name: "SwiftToolchainCSQLite",
                 package: "swift-toolchain-sqlite",
                 condition: .when(traits: ["SwiftToolchainCSQLite"])),
        .product(name: "SQLCipher",
                 package: "SQLCipher.swift",
                 condition: .when(platforms: applePlatforms, traits: ["SQLCipher"]))
    ],
    exclude: ["Info.plist"],
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
        .library(name: "SQLite", targets: ["SQLite"])
    ],
    traits: [
        .trait(name: "SQLCipher",
               description: "Enables SQLCipher encryption when a key is supplied to Connection"),
        .trait(name: "SwiftToolchainCSQLite",
               description: "Uses the SQLite from SwiftToolchain")
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-toolchain-sqlite", from: "1.0.7"),
        .package(url: "https://github.com/sqlcipher/SQLCipher.swift.git", from: "4.11.0")
    ],
    targets: [target, testTarget],
    swiftLanguageModes: [.v5],
)
