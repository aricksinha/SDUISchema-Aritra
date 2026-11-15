//
//  RendererRegistry.swift
//
//
//  Created by Aritra on 13/11/26.
//

import Foundation

/// Maps a node `type` string to the renderer that handles it.

/// Built once at the Composition Root, then passed down. It is a value type with no global instance and no singleton. Tests build their own registry with exactly the renderers they need.
/// Adding a component means registering one more renderer. Nothing existing changes. A type with no registered renderer resolves to the fallback, so lookup never fails and never returns an optional.
/// The registry doesn’t report unknown types yet. Lookup happens inside SwiftUI’s body, which can re-evaluate many times per screen. Reporting there would flood telemetry with duplicates. The right place is a once-per-screen pass, which I’ll add when we wire analytics. For now, the debug chip covers local development.
/// Lookup is an exact, case-sensitive match. "Text" and "text" are different types. That’s deliberate, since silent normalization is how contract drift hides, and the JSON Schema lint is the right place to enforce naming.
public struct RendererRegistry {
    private var renderers: [String: NodeRenderer]
    private let fallback: NodeRenderer
    
    /// Public so a host Composition Root can build the registry.
    /// The demo app is the first consumer; it must not need `@testable`.
    public init(fallback: NodeRenderer = UnknownNodePlaceholder()) {
        self.renderers = [:]
        self.fallback = fallback
    }
    
    /// Registering a type that already has a renderer replaces it (last registration wins). That is intentional: a host app can override a built-in component, such as a custom text renderer, without forking the SDK.
    public mutating func register(_ renderer: NodeRenderer, for type: String) {
        renderers[type] = renderer
    }
    
    public func renderer(for type: String) -> NodeRenderer {
        renderers[type] ?? fallback
    }
    
    /// Whether `type` has an explicitly registered renderer, as opposed  to resolving to the fallback.
    public func isRegistered(_ type: String) -> Bool {
        renderers[type] != nil
    }
}
