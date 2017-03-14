import PackageDescription

let package = Package(
    name: "SQLite",
    targets: [
        Target(name: "SQLite")
    ],
    dependencies: [
        .Package(url: "https://github.com/stephencelis/CSQLite.git", majorVersion: 0)
    ],
    exclude: ["Tests/CocoaPods", "Tests/Carthage"]
)

#if os(Linux)
    package.exclude.append(contentsOf: [
        "Sources/SQLiteObjc",
        "Sources/SQLite/Extensions/FTS4.swift",
        "Sources/SQLite/Extensions/FTS5.swift",
        "Tests/SQLiteTests/FTS4Tests.swift",
        "Tests/SQLiteTests/FTS5Tests.swift"
    ])
#else
    let objcTarget = Target(name: "SQLiteObjc")
    package.targets.first?.dependencies.append(.Target(name: objcTarget.name))
    package.targets.append(objcTarget)
#endif
