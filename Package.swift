// swift-tools-version:5.6.2
import PackageDescription

let package = Package(
    name: "RhythmTrainer",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "RhythmTrainer",
            targets: ["RhythmTrainer"]
        )
    ],
    targets: [
        .target(
            name: "RhythmTrainer",
            dependencies: [],
            path: "Sources/RhythmTrainer",
            resources: [
                .process("Resources")
            ]
        )
    ]
)