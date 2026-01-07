// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "PhotobookApp",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "PhotobookApp", targets: ["PhotobookApp"])
    ],
    targets: [
        .executableTarget(
            name: "PhotobookApp",
            path: "Sources"
        )
    ]
)
