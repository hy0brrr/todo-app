// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "TodoApp",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "TodoApp",
            path: "TodoApp"
        )
    ]
)
