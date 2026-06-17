// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Whiteout",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "Whiteout",
            dependencies: [],
            path: "Sources/Whiteout",
            linkerSettings: [
                // Carbon framework: EventHotKey API (RegisterEventHotKey 등)
                .linkedFramework("Carbon")
            ]
        )
    ]
)
