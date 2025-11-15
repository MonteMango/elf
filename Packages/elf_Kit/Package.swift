// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "elf_Kit",
    platforms: [
            .iOS(.v18)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "elf_Kit",
            targets: ["elf_Kit"]),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "elf_Kit",
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]),
        .testTarget(
            name: "elf_KitTests",
            dependencies: ["elf_Kit"],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]),
    ]
)
