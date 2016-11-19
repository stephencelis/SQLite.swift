import PackageDescription

let package = Package(
    name: "SQLite.swift",
    targets: [
        Target(
            name: "SQLite",
            dependencies: [
                .Target(name: "CSQLite")
            ]),
        Target(
            name: "CSQLite")
    ]
)
