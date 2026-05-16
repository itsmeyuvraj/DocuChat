// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "DocChat",
    platforms: [.macOS("26.0")],
    targets: [
        .executableTarget(
            name: "DocChat",
            path: "Sources/DocChat",
            exclude: ["Resources", "Info.plist", "DocChat.entitlements"]
        )
    ]
)
