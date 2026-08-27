// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "TimeMaker",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "TimeMaker", targets: ["TimeMaker"])
    ],
    targets: [
        .target(
            name: "TimeMakerCore"
        ),
        .executableTarget(
            name: "TimeMaker",
            dependencies: ["TimeMakerCore"],
            exclude: ["Resources"]
        ),
        .testTarget(
            name: "TimeMakerCoreTests",
            dependencies: ["TimeMakerCore"]
        )
    ]
)
