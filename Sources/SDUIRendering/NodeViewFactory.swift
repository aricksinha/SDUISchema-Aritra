//
//  NodeViewFactory.swift
//
//
//  Created by Aritra on 13/11/26.
//

import SwiftUI
import SDUISchema
import SDUIDesignSystem

/// The single function that turns a node into a view: look up the renderer for `node.type`, hand it a context, return its view.
/// Recursion lives here. The context handed to each renderer carries a closure that calls this same function for a child, so a container renderer renders its children without knowing the registry exists.
/// Keeping every node's rendering behind this one function matters for the next steps. The accessibility and analytics decorators will wrap the result of `makeView` here, once, so they apply to every component without any renderer knowing about them.
/// ** This is internal on purpose. Host apps use SDUIView **
func makeNodeView(
    _ node: Node,
    theme: Theme,
    registry: RendererRegistry
) -> AnyView {
    let context = RenderContext(theme: theme) { child in
        makeNodeView(child, theme: theme, registry: registry)
    }
    let view = registry.renderer(for: node.type).makeView(for: node, context: context)

    // Unknown types get no box. In release the placeholder is empty,
    // and a padded, colored empty view would show up as a stray
    // rectangle on a real user's screen.
    guard registry.isRegistered(node.type),
          let box = BoxStyle.resolve(node.style, using: theme) else { return view }
    return AnyView(view.modifier(BoxStyleModifier(box: box)))
}
