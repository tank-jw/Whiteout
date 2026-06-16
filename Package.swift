// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Whiteout",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [
        .package(url: "https://github.com/sindresorhus/KeyboardShortcuts", exact: "1.9.0")
    ],
    targets: [
        .executableTarget(
            name: "Whiteout",
            dependencies: [
                "KeyboardShortcuts"
            ],
            path: "Sources/Whiteout"
        )
    ]
)
