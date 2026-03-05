// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "RockCrabShared",
    platforms: [
        .iOS(.v17),
        .macOS(.v11)
    ],
    products: [
        .library(name: "RockCrabShared", targets: ["RockCrabShared"])
    ],
    targets: [
        .target(
            name: "RockCrabShared",
            path: "Sources/RockCrabShared"
        ),
        .testTarget(
            name: "RockCrabSharedTests",
            dependencies: ["RockCrabShared"],
            path: "Tests/RockCrabSharedTests"
        )
    ]
)
