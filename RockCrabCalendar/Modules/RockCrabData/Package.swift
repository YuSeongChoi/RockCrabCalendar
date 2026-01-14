// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "RockCrabData",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "RockCrabData", targets: ["RockCrabData"])
    ],
    dependencies: [
        .package(path: "../RockCrabShared"),
        .package(path: "../RockCrabDomain"),
        .package(url: "https://github.com/Alamofire/Alamofire", from: "5.9.0"),
        .package(url: "https://github.com/firebase/firebase-ios-sdk", from: "12.0.0")
    ],
    targets: [
        .target(
            name: "RockCrabData",
            dependencies: [
                "RockCrabShared",
                "RockCrabDomain",
                "Alamofire",
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk")
            ],
            path: "Sources/RockCrabData"
        )
    ]
)
