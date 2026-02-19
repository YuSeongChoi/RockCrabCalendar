// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "RockCrabDomain",
    platforms: [.iOS(.v17), .macOS(.v13)],
    products: [
        .library(name: "RockCrabDomain", targets: ["RockCrabDomain"])
    ],
    dependencies: [
        .package(path: "../RockCrabShared")
    ],
    targets: [
        .target(
            name: "RockCrabDomain",
            dependencies: ["RockCrabShared"],
            path: "Sources/RockCrabDomain"
        ),
        .testTarget(
            name: "RockCrabDomainTests",
            dependencies: ["RockCrabDomain"],
            path: "Tests/RockCrabDomainTests"
        )
    ]
)
