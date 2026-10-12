// swift-tools-version:5.9
import PackageDescription

// SDUISchema is the ONE package in the whole SDK that has zero
// dependencies and imports no Apple UI framework. That's not an
// accident — it's the enforcement mechanism for "the contract layer
// doesn't know SwiftUI exists." If this target ever needs to import
// SwiftUI or UIKit to compile, something has leaked across the seam.
let package = Package(
    name: "SDUISchema",
    platforms: [.iOS(.v15), .macOS(.v12), .tvOS(.v15), .watchOS(.v8)],
    products: [
        .library(name: "SDUISchema", targets: ["SDUISchema"])
    ],
    targets: [
        .target(name: "SDUISchema"),
        .testTarget(
            name: "SDUISchemaTests",
            dependencies: ["SDUISchema"],
            resources: [.copy("Fixtures")]
        )
    ]
)
