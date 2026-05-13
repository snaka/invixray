// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Invixray",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "InvixrayCore", targets: ["InvixrayCore"]),
    ],
    targets: [
        .target(name: "InvixrayCore"),
        .testTarget(name: "InvixrayCoreTests", dependencies: ["InvixrayCore"]),
    ]
)
