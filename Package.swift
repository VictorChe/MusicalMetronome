
// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "RhythmTrainer",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .executable(name: "RhythmTrainer", targets: ["RhythmTrainer"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "RhythmTrainer",
            dependencies: [],
            path: ".",
            sources: ["Sources/RhythmTrainer", "Models", "Views"]
        ),
        .testTarget(
            name: "workspaceTests",
            dependencies: ["RhythmTrainer"],
            path: "Tests"
        )
    ]
)
