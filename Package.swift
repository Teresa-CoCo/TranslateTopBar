// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TranslateTopBar",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(name: "TranslateTopBar", targets: ["TranslateTopBarApp"])
    ],
    targets: [
        .target(
            name: "TranslateTopBarApp",
            path: "Sources"
        )
    ]
)
