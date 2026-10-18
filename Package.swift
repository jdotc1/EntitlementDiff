// swift-tools-version: 6.0
import PackageDescription

var products: [Product] = [
    .library(name: "EntitlementDiffCore", targets: ["EntitlementDiffCore"]),
    .library(name: "EntitlementDiffModel", targets: ["EntitlementDiffModel"])
]
var targets: [Target] = [
    .target(name: "EntitlementDiffCLIKit", dependencies: ["EntitlementDiffCore"]),
    .testTarget(name: "EntitlementDiffCLITests", dependencies: ["EntitlementDiffCLIKit", "EntitlementDiffCore"]),
    .target(name: "EntitlementDiffCore"),
    .target(name: "EntitlementDiffModel", dependencies: ["EntitlementDiffCore"]),
    .testTarget(name: "EntitlementDiffCoreTests", dependencies: ["EntitlementDiffCore"]),
    .testTarget(name: "EntitlementDiffModelTests", dependencies: ["EntitlementDiffModel"])
]
#if os(macOS)
products += [
    .library(name: "EntitlementDiffSecurity", targets: ["EntitlementDiffSecurity"]),
    .executable(name: "EntitlementDiff", targets: ["EntitlementDiffApp"]),
    .executable(name: "entitlementdiff-cli", targets: ["EntitlementDiffCLI"])
]
targets += [
    .executableTarget(name: "EntitlementDiffCLI", dependencies: ["EntitlementDiffCLIKit", "EntitlementDiffSecurity"]),
    .target(name: "EntitlementDiffSecurity", dependencies: ["EntitlementDiffCore"],
            linkerSettings: [.linkedFramework("Security")]),
    .executableTarget(name: "EntitlementDiffApp", dependencies: [
        "EntitlementDiffCore", "EntitlementDiffModel", "EntitlementDiffSecurity"
    ]),
    .testTarget(name: "EntitlementDiffSecurityTests", dependencies: ["EntitlementDiffCore", "EntitlementDiffSecurity"]),
    .testTarget(name: "EntitlementDiffAppTests", dependencies: ["EntitlementDiffApp", "EntitlementDiffCore", "EntitlementDiffModel"])
]
#endif
let package = Package(
    name: "EntitlementDiff", platforms: [.macOS(.v14)],
    products: products, targets: targets, swiftLanguageModes: [.v6]
)
