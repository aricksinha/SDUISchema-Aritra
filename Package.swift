// swift-tools-version:5.9
import PackageDescription

// SDUISchema is the ONE package in the whole SDK that has zero
// dependencies and imports no Apple UI framework. That's not an
// accident — it's the enforcement mechanism for "the contract layer
// doesn't know SwiftUI exists." If this target ever needs to import
// SwiftUI or UIKit to compile, something has leaked across the seam.
// swift-tools-version:5.9

let package = Package(
    name: "SDUIKit",
    platforms: [.iOS(.v15), .macOS(.v12), .tvOS(.v15), .watchOS(.v8)],
    products: [
        .library(name: "SDUISchema", targets: ["SDUISchema"]),
        .library(name: "SDUIDesignSystem", targets: ["SDUIDesignSystem"]),
        .library(name: "SDUIRendering", targets: ["SDUIRendering"])
    ],
    targets: [
        .target(name: "SDUISchema"),
        .target(name: "SDUIDesignSystem", dependencies: ["SDUISchema"]),
        .target(
            name: "SDUIRendering",                                      // new
            dependencies: ["SDUISchema", "SDUIDesignSystem"]
        ),
        .testTarget(
            name: "SDUIRenderingTests",                                 // new
            dependencies: ["SDUIRendering", "SDUISchema", "SDUIDesignSystem"]
        ),
        .testTarget(name: "SDUISchemaTests", dependencies: ["SDUISchema"], resources: [.copy("Fixtures")]),
        .testTarget(name: "SDUIDesignSystemTests", dependencies: ["SDUIDesignSystem"])
    ]
)
