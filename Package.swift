// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "DevKit",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "DevKit",
            path: "DevKit",
            resources: [
                .process("Resources")
            ]
        )
    ]
)
