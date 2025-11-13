// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "ChromaUseCases",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "ChromaUseCases",
            targets: ["ChromaUseCases"]
        ),
    ],
    dependencies: [
        // Local dependency on ChromaDomain (same workspace)
        .package(path: "../ChromaDomain")
    ],
    targets: [
        .target(
            name: "ChromaUseCases",
            dependencies: [
                "ChromaDomain"
            ],
            path: "Sources"
        )
    ]
)
