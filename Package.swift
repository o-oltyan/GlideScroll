// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "GlideScroll",
    platforms: [.macOS(.v15)],
    targets: [
        .executableTarget(
            name: "GlideScroll",
            path: "Sources/GlideScroll"
        )
    ]
)
