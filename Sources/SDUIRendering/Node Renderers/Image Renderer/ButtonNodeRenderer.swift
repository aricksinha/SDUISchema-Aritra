//
//  ButtonNodeRenderer.swift
//
//
//  Created by Aritra on 21/11/26.
//

import SwiftUI
import SDUISchema

/// Renders `type: "button"`.
///
/// Label resolution: a `title` prop for the common text button, or the
/// node's children for a composed label (icon + text, etc.). The tap
/// forwards `actionID` to the context's dispatcher — the renderer has no idea what the action does.
public struct ButtonNodeRenderer: NodeRenderer {
    public init() {}
    
    public func makeView(
        for node: SDUISchema.Node,
        context: RenderContext
    ) -> AnyView {
        let label = makeLabel(for: node, context: context)
        
        /// No action id → render the label, but not as a tappable control.A button that silently does nothing is worse than a plain label.
        guard let actionID = node.actionID else { return label }
        return AnyView(
            Button(action: { context.dispatch(actionID: actionID) }) { label
            }
        )
    }
    
    private func makeLabel(
        for node: Node,
        context: RenderContext
    ) -> AnyView {
        if let title = node.props?["title"]?.stringValue {
            return AnyView(Text(title))
        }
        let children = context.childViews(of: node)
        guard !children.isEmpty else { return AnyView(EmptyView()) }
        return AnyView(
            HStack(spacing: 8) {
                ForEach(children) { $0.view }
            }
        )
    }
}
