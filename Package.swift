// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AwkTalk2",
    platforms: [.iOS(.v16)],
    products: [
        .library(name: "AwkTalk2", targets: ["AwkTalk2"]),
    ],
    dependencies: [
        .package(url: "https://github.com/ml-explore/mlx-swift-examples/", branch: "main"),
    ],
    targets: [
        .target(
            name: "AwkTalk2",
            dependencies: [
                .product(name: "MLXLLM", package: "mlx-swift-examples"),
                .product(name: "MLXLLMCommon", package: "mlx-swift-examples")
            ]
        ),
        .testTarget(
            name: "AwkTalk2Tests",
            dependencies: ["AwkTalk2"]
        ),
    ]
) 