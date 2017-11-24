// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "StatusBar",
    products: [
        .executable(name: "StatusBar", targets: ["StatusBar"])
    ],
    dependencies: [],
    targets: [
        .target(name: "StatusBar", dependencies: [])
    ]
)
