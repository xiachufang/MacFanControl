// swift-tools-version:6.3
import PackageDescription

let approachable: [SwiftSetting] = [
    .enableUpcomingFeature("InferIsolatedConformances"),
    .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
]

let package = Package(
    name: "MacFanControl",
    platforms: [.macOS(.v26)],
    products: [
        .library(name: "SMCKit", targets: ["SMCKit"]),
        .library(name: "FanDomain", targets: ["FanDomain"]),
        .library(name: "HelperIPC", targets: ["HelperIPC"]),
    ],
    targets: [
        .target(name: "SMCKit", swiftSettings: approachable),
        .target(name: "FanDomain", dependencies: ["SMCKit"], swiftSettings: approachable),
        .target(name: "HelperIPC", swiftSettings: approachable),

        .testTarget(name: "SMCKitTests", dependencies: ["SMCKit"], swiftSettings: approachable),
        .testTarget(name: "FanDomainTests", dependencies: ["FanDomain", "SMCKit"], swiftSettings: approachable),
        .testTarget(name: "HelperIPCTests", dependencies: ["HelperIPC"], swiftSettings: approachable),
    ],
    swiftLanguageModes: [.v6]
)
