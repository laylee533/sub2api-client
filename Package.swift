// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Sub2APIMonitorApp",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "Sub2APIMonitorApp", targets: ["Sub2APIMonitorApp"])
    ],
    targets: [
        .executableTarget(
            name: "Sub2APIMonitorApp"
        ),
        .testTarget(
            name: "Sub2APIMonitorTests",
            dependencies: ["Sub2APIMonitorApp"]
        )
    ]
)
