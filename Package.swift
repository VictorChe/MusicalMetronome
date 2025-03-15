
// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "RhythmTrainer",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(
            name: "RhythmTrainer",
            targets: ["RhythmTrainer"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "RhythmTrainer",
            dependencies: [],
            path: "Sources/RhythmTrainer"
        ),
        .testTarget(
            name: "RhythmTrainerTests",
            dependencies: ["RhythmTrainer"]
        )
    ]
)
