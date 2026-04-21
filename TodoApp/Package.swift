// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TodoApp",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "TodoApp",
            path: "TodoApp",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "TodoAppTests",
            dependencies: ["TodoApp"],
            path: "Tests/TodoAppTests"
        )
    ]
)
