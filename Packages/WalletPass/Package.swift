// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "WalletPass",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "WalletPass", targets: ["WalletPass"]),
    ],
    targets: [
        .target(name: "WalletPass"),
        .testTarget(name: "WalletPassTests", dependencies: ["WalletPass"]),
    ]
)
