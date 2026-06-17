// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "WhiteOut",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "WhiteOut",
            dependencies: [],
            path: "Sources/Whiteout",
            linkerSettings: [
                // Carbon framework: EventHotKey API (RegisterEventHotKey 등)
                .linkedFramework("Carbon")
            ]
        )
    ]
)
