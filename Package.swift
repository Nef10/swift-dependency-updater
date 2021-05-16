// swift-tools-version:5.2

import PackageDescription

let package = Package(
    name: "SwiftDependencyUpdater",
    platforms: [
        .macOS(.v10_11),
    ],
    products: [
        .library(
            name: "SwiftDependencyUpdaterLibrary",
            targets: ["SwiftDependencyUpdaterLibrary"]
        ),
        .executable(
            name: "swift-dependency-updater",
            targets: ["SwiftDependencyUpdater"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/apple/swift-argument-parser",
            .upToNextMinor(from: "0.3.1")
        ),
        .package(
            url: "https://github.com/Nef10/ShellOut.git",
            .upToNextMajor(from: "2.3.1")
        ),
        .package(
            url: "https://github.com/onevcat/Rainbow.git",
            .upToNextMajor(from: "4.0.0")
        ),
        .package(
            url: "https://github.com/Nef10/Releases.git",
            .upToNextMajor(from: "5.0.1")
        ),
    ],
    targets: [
        .target(
            name: "SwiftDependencyUpdaterLibrary",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                "ShellOut",
                "Rainbow",
                "Releases",
            ]
        ),
        .testTarget(
            name: "SwiftDependencyUpdaterLibraryTests",
            dependencies: [
                "SwiftDependencyUpdaterLibrary"
            ]
        ),
        .target(
            name: "SwiftDependencyUpdater",
            dependencies: [
                "SwiftDependencyUpdaterLibrary"
            ]
        ),
    ]
)
