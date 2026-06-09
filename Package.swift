// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Cratebar",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "Cratebar",
            path: "Sources/Cratebar",
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        )
    ]
)
