// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Invixray",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "InvixrayCore", targets: ["InvixrayCore"]),
        .library(name: "InvixrayMonitor", targets: ["InvixrayMonitor"]),
    ],
    targets: [
        .target(name: "InvixrayCore"),
        .target(name: "InvixrayMonitor", dependencies: ["InvixrayCore"]),
        .testTarget(name: "InvixrayCoreTests", dependencies: ["InvixrayCore"]),
        .testTarget(name: "InvixrayMonitorTests", dependencies: ["InvixrayMonitor"]),
    ]
)
