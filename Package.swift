
// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "RhythmTrainer",
    platforms: [
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
            exclude: ["Tests", ".build", "attached_assets", ".gitignore", ".replit", "README.md", "generated-icon.png"],
            sources: ["Models", "Views", "Sources/RhythmTrainer"]
        ),
        .testTarget(
            name: "RhythmTrainerTests",
            dependencies: ["RhythmTrainer"],
            path: "Tests"
        )
    ]
)
