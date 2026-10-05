// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CyberBlessing",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "CyberBlessingCore", targets: ["CyberBlessingCore"]),
        .executable(name: "CyberBlessing", targets: ["CyberBlessing"]),
        .executable(name: "CyberBlessingChecks", targets: ["CyberBlessingChecks"])
    ],
    targets: [
        .target(name: "CyberBlessingCore"),
        .executableTarget(name: "CyberBlessing", dependencies: ["CyberBlessingCore"], resources: [.process("Resources")]),
        .target(name: "CyberBlessingCheckSupport", dependencies: ["CyberBlessingCore"], path: "Tests/CheckSupport"),
        .executableTarget(name: "CyberBlessingChecks", dependencies: ["CyberBlessingCheckSupport"], path: "Tools/CoreChecks"),
        .testTarget(name: "CyberBlessingTests", dependencies: ["CyberBlessingCheckSupport"])
    ]
)
