// swift-tools-version:5.6.2
import PackageDescription

let package = Package(
    name: "RhythmTrainer",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .executable(name: "RhythmTrainer", targets: ["RhythmTrainer"])
    ],
    targets: [
        .executableTarget(
            name: "RhythmTrainer",
            path: "Sources"
        )
    ]
)