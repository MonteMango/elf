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
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.4.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "elf_Kit",
            dependencies: [
                .product(name: "Dependencies", package: "swift-dependencies"),
            ],
            swiftSettings: [
                .enableExperimentalFeature("DebugDescriptionMacro")
            ]),
        .testTarget(
            name: "elf_KitTests",
            dependencies: [
                "elf_Kit",
                .product(name: "DependenciesTestSupport", package: "swift-dependencies"),
            ],
            swiftSettings: [
                .enableExperimentalFeature("DebugDescriptionMacro")
            ]),
        .testTarget(
            name: "battle_simulation_IntegrationTests",
            dependencies: [
                "elf_Kit",
                .product(name: "DependenciesTestSupport", package: "swift-dependencies"),
            ],
            swiftSettings: [
                .enableExperimentalFeature("DebugDescriptionMacro")
            ]),
    ], swiftLanguageModes: [.v6]
)
