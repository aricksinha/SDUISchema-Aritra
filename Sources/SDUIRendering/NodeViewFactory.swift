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
    registry: RendererRegistry,
    onAction: @escaping (String) -> Void = { _ in }
) -> AnyView {
    let context = RenderContext(
        theme: theme,
        renderNode: { child in
            makeNodeView(child, theme: theme, registry: registry, onAction: onAction)
        },
        dispatchAction: onAction
    )
    let renderer = registry.renderer(for: node.type)
    var view = renderer.makeView(for: node, context: context)

    if let box = BoxStyle.resolve(node.style, using: theme) {
        view = AnyView(view.modifier(BoxStyleModifier(box: box)))
    }
    if let actionID = node.actionID, renderer.appliesNodeTapAction {
        view = AnyView(view.modifier(TapActionModifier(actionID: actionID, dispatch: onAction)))
    }
    return view
}
