//
//  UnknownNodePlaceholder.swift
//
//
//  Created by Aritra on 13/11/26.
//

import SwiftUI
import SDUISchema

/// What renders when a node's `type` has no registered renderer.
///
/// This is the render-time half of "unknown vocabulary is never a
/// failure." `SDUISchema` happily decodes any `type` string, and this
/// is where an unrecognized one lands. A server can ship a new
/// component before every client supports it and old clients just
/// skip it.
///
/// In production it renders nothing, so users never see a broken-looking
/// block. In debug builds it shows a visible chip with the type name,
/// so QA and developers catch "the server sent something we can't
/// render" immediately instead of wondering why a section is missing.
public struct UnknownNodePlaceholder: NodeRenderer {
    public let showsDiagnostics: Bool

    /// Injectable so tests can exercise both modes without depending on
    /// the build configuration. Hosts normally use the default.
    public init(showsDiagnostics: Bool = UnknownNodePlaceholder.defaultShowsDiagnostics) {
        self.showsDiagnostics = showsDiagnostics
    }

    public static var defaultShowsDiagnostics: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }

    public func makeView(for node: Node, context: RenderContext) -> AnyView {
        guard showsDiagnostics else { return AnyView(EmptyView()) }

        // Deliberately does not use theme tokens. A diagnostic must
        // stay visible even if the theme is the thing that's broken.
        return AnyView(
            Text("Unsupported: \(node.type)")
                .font(.caption2)
                .foregroundColor(.secondary)
                .padding(4)
                .background(Color.yellow.opacity(0.25))
        )
    }
}
