// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

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
    dependencies: [],
    targets: [
        .target(
            name: "RhythmTrainer",
            dependencies: [],
            path: "Sources/RhythmTrainer"
        )
    ]
)