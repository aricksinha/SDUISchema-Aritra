//
//  StackNodeRenderer.swift
//
//
//  Created by Aritra on 14/11/26.
//

import SwiftUI
import SDUISchema
import SDUIDesignSystem


/// Renders `type: "stack"`
/// `vertical` and `horizontal` lay children out along one axis overlay` layers them, with the first child at the back, the same order as a SwiftUI `ZStack`.

/// Children come from `context.childViews(of:)`, which has already skipped quarantined slots and carries each child's `id` as its identity. `ForEach` uses that id, so a server that reorders children produces a move, not a teardown and rebuild
/// Spacing is always explicit. With no `spacingToken` it is 0, not SwiftUI's adaptive default, so the server fully controls layout and the same payload looks the same across OS versions.
public struct StackNodeRenderer: NodeRenderer {
    public init() {}
    
    public func makeView(
        for node: SDUISchema.Node,
        context: RenderContext
    ) -> AnyView {
        let layout = ResolvedLayout.resolve(node.layout, using: context.theme)
        let children = context.childViews(of: node)
        switch layout.direction {
        case .vertical:
            return AnyView(
                VStack(alignment: StackAlignment.horizontal(layout.alignment), spacing: layout.spacing) {
                    ForEach(children) { $0.view }
                }
            )
        case .horizontal:
            return AnyView(
                HStack(alignment: StackAlignment.vertical(layout.alignment), spacing: layout.spacing) {
                    ForEach(children) { $0.view }
                }
            )
        case .overlay:
            return AnyView(
                ZStack(alignment: StackAlignment.overlay(layout.alignment)) {
                    ForEach(children) { $0.view }
                }
            )
        }
    }
}

/// Maps the wire's single `LayoutSpec.Alignment` onto the alignment type each SwiftUI stack expects.

/// The wire enum mixes axes (`leading` is horizontal, `top` is  vertical) so the server only needs one field. An alignment that doesn't apply to the stack's axis, such as `top` on a vertical stack, degrades to `center` instead of failing. It's a pure function so every combination is unit tested without rendering.
enum StackAlignment {
    /// Cross-axis alignment for a vertical stack.
    static func horizontal(
        _ alignment: SDUISchema.Layout.Alignment?
    ) -> HorizontalAlignment {
        switch alignment {
        case .leading: return .leading
        case .trailing: return .trailing
        case .center, .top, .bottom, nil: return .center
        }
    }

    /// Cross-axis alignment for a horizontal stack.
    static func vertical(
        _ alignment: SDUISchema.Layout.Alignment?
    ) -> VerticalAlignment {
        switch alignment {
        case .top: return .top
        case .bottom: return .bottom
        case .center, .leading, .trailing, nil: return .center
        }
    }

    /// Placement for an overlay. Every value applies here.
    static func overlay(
        _ alignment: SDUISchema.Layout.Alignment?
    ) -> Alignment {
        switch alignment {
        case .leading: return .leading
        case .trailing: return .trailing
        case .top: return .top
        case .bottom: return .bottom
        case .center, nil: return .center
        }
    }
}
