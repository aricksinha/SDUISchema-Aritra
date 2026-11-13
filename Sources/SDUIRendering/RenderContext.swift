//
//  RenderContext.swift
//
//
//  Created by Aritra on 13/11/26.
//

import SwiftUI
import SDUISchema
import SDUIDesignSystem

/// Everything a renderer needs besides the node itself.
/// Renderers never see the registry. ** Containers (stack, card) ** need to render their children, so the context hands them a closure that does it. A renderer can then recurse without knowing how node types map to renderers, and it can be unit tested with a fake closure instead of a real registry.
public struct RenderContext {
    public let theme: Theme
    private let renderNode: (Node) -> AnyView
    
    public init(theme: Theme, renderNode: @escaping (Node) -> AnyView) {
        self.theme = theme
        self.renderNode = renderNode
    }
    
    public func render(_ node: Node) -> AnyView {
        renderNode(node)
    }
    
    /// Renders the healthy children of a node. Quarantined (`.failed`) slots are skipped here, once, so no individual renderer has to remember to handle them.  Each result carries the child's own `id` as its identity. SwiftUI needs stable identity from data rather than array position, or  reordered and refreshed lists flicker.
    public func childViews(of node: Node) -> [RenderedChild] {
        node.children.compactMap { slot in
            guard let child = slot.node else { return nil }
            return RenderedChild(id: child.id, view: render(child))
        }
    }
}

public struct RenderedChild: Identifiable {
    public let id: String
    public let view: AnyView
}
