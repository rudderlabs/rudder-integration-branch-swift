// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "RudderBranch",
    platforms: [
        .iOS("13.0"), .tvOS("11.0")
    ],
    products: [
        .library(
            name: "RudderBranch",
            targets: ["RudderBranch"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/BranchMetrics/ios-branch-deep-linking-attribution", "1.41.0"..<"1.41.1"),
        .package(url: "https://github.com/rudderlabs/rudder-sdk-ios", from: "2.0.0"),
    ],
    targets: [
        .target(
            name: "RudderBranch",
            dependencies: [
                .product(name: "Branch", package: "ios-branch-deep-linking-attribution"),
                .product(name: "Rudder", package: "rudder-sdk-ios"),
            ],
            path: "Sources",
            sources: ["Classes/"]
        )
    ]
)
