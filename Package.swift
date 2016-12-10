import PackageDescription

let package = Package(
    name: "SQLite",
    targets: [
        Target(
            name: "SQLite",
            dependencies: [
                .Target(name: "SQLiteObjc")
            ]),
        Target(name: "SQLiteObjc")
    ],
    dependencies: [
        .Package(url: "https://github.com/jberkel/CSQLite.git", majorVersion: 0)
    ]
)
