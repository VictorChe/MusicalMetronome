// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "RhythmTrainer",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .executable(
            name: "RhythmTrainer",
            targets: ["RhythmTrainer"]
        )
    ],
    targets: [
        .executableTarget(
            name: "RhythmTrainer",
            dependencies: [],
            path: "Sources/RhythmTrainer",
            resources: [
                .process("Resources")
            ]
        )
    ]
)