// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ShortcutRecorder",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .library(name: "ShortcutRecorder", targets: ["ShortcutRecorder"])
    ],
    dependencies: [
        .package(url: "https://github.com/Ricka7x/KeyboardShortcuts", from: "2.4.1-snapback.2")
    ],
    targets: [
        .target(
            name: "ShortcutRecorder",
            dependencies: [
                .product(name: "KeyboardShortcuts", package: "KeyboardShortcuts")
            ]
        ),
        .testTarget(
            name: "ShortcutRecorderTests",
            dependencies: ["ShortcutRecorder"]
        ),
    ]
)
