// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ElectrumKit",
    platforms: [
            .iOS(.v13)
        ],
    products: [
        .library(
            name: "ElectrumKit",
            targets: ["ElectrumKit"]),
    ],
    dependencies: [
        .package(
            url: "https://github.com/FlorianHubl/EasyTCP",
            .branch("main")
        ),
        .package(
            url: "https://github.com/FlorianHubl/MempoolKit",
            .branch("main")
        ),
        .package(
            url: "https://github.com/FlorianHubl/LibWally",
            .branch("main")
        )
    ],
    targets: [
        .target(
            name: "ElectrumKit",
            dependencies: ["EasyTCP", "MempoolKit", "LibWally"]),
        .testTarget(
            name: "ElectrumKitTests",
            dependencies: ["ElectrumKit"]),
    ]
)
