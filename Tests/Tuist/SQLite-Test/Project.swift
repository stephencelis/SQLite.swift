import ProjectDescription

let project = Project(
    name: "SQLite-Test",
    targets: [
        .target(
            name: "SQLite-Test",
            destinations: .iOS,
            product: .app,
            bundleId: "dev.tuist.SQLite-Test",
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchScreen": [
                        "UIColorName": "",
                        "UIImageName": "",
                    ],
                ]
            ),
            buildableFolders: [
                "SQLite-Test/Sources",
                "SQLite-Test/Resources",
            ],
            dependencies: []
        ),
        .target(
            name: "SQLite-TestTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "dev.tuist.SQLite-TestTests",
            infoPlist: .default,
            buildableFolders: [
                "SQLite-Test/Tests"
            ],
            dependencies: [.target(name: "SQLite-Test")]
        ),
    ]
)
