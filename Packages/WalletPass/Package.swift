// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "WalletPass",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "WalletPass", targets: ["WalletPass"]),
    ],
    dependencies: [
        // CMS signing is SPI, so pin it. 1.9.0 drops intermediate certificates when a
        // signing time is set (apple/swift-certificates#289); move back to a tagged
        // release once the fix ships in one.
        .package(url: "https://github.com/apple/swift-certificates.git", revision: "7d5f6124c91a2d06fb63a811695a3400d15a100e"),
        .package(url: "https://github.com/apple/swift-crypto.git", from: "3.12.3"),
        .package(url: "https://github.com/apple/swift-asn1.git", from: "1.1.0"),
    ],
    targets: [
        .target(
            name: "WalletPass",
            dependencies: [
                .product(name: "X509", package: "swift-certificates"),
                .product(name: "Crypto", package: "swift-crypto"),
                .product(name: "SwiftASN1", package: "swift-asn1"),
            ],
            resources: [.copy("Resources/AppleWWDRCAG4.cer")]
        ),
        .testTarget(
            name: "WalletPassTests",
            dependencies: [
                "WalletPass",
                .product(name: "X509", package: "swift-certificates"),
                .product(name: "_CryptoExtras", package: "swift-crypto"),
                .product(name: "SwiftASN1", package: "swift-asn1"),
            ]
        ),
    ]
)
