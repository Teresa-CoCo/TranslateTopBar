// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TranslateTopBar",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "TranslateTopBarApp", targets: ["TranslateTopBarApp"])
    ],
    targets: [
        .executableTarget(
            name: "TranslateTopBarApp",
            path: "Sources"
        )
    ]
)
