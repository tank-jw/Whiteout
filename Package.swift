// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "WhiteOut",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "WhiteOutKit",
            targets: ["WhiteOutKit"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "WhiteOut",
            dependencies: [
                "WhiteOutKit"
            ],
            path: "Sources/Whiteout",
            linkerSettings: [
                .linkedFramework("Carbon")
            ]
        ),
        .target(
            name: "WhiteOutKit",
            dependencies: [],
            path: "Sources/WhiteOutKit",
            linkerSettings: [
                .linkedFramework("Carbon")
            ]
        ),
        .testTarget(
            name: "WhiteOutKitTests",
            dependencies: ["WhiteOutKit"],
            path: "Tests/WhiteOutKitTests"
        )
    ]
)
