// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "ReduceWhitePoint",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "ReduceWhitePoint",
            path: "Sources/ReduceWhitePoint"
        )
    ]
)
