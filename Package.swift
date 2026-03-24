// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Dictate",
    platforms: [
        .macOS(.v15) // Will target macOS 26 at runtime; SPM doesn't have .v26 yet
    ],
    products: [
        .executable(name: "Dictate", targets: ["Dictate"])
    ],
    dependencies: [
        .package(url: "https://github.com/sindresorhus/KeyboardShortcuts", from: "2.0.0"),
        .package(url: "https://github.com/ml-explore/mlx-swift", from: "0.30.3"),
        .package(url: "https://github.com/ml-explore/mlx-swift-lm", from: "2.30.3"),
    ],
    targets: [
        .executableTarget(
            name: "Dictate",
            dependencies: [
                "KeyboardShortcuts",
                .product(name: "MLX", package: "mlx-swift"),
                .product(name: "MLXLLM", package: "mlx-swift-lm"),
                .product(name: "MLXLMCommon", package: "mlx-swift-lm"),
            ],
            path: "Sources/Dictate",
            resources: [
                .process("../../Resources")
            ]
        ),
        .testTarget(
            name: "DictateTests",
            dependencies: ["Dictate"],
            path: "Tests/DictateTests"
        ),
    ]
)
