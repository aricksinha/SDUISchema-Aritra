//
//  TextNodeRenderer.swift
//
//
//  Created by Aritra on 13/11/26.
//

import SwiftUI
import SDUISchema
import SDUIDesignSystem

/// The typed view of a text node's opaque `props`.

/// `Node.props` is generic JSON on purpose. This is where the text
/// component interprets its own slice of it. Reading never throws.
/// Every field degrades to `nil` when absent or malformed, the same
/// philosophy as the schema layer.
struct TextProps: Equatable {
    let content: String?
    let lineLimit: Int?
    
    init(_ props: JSONValue?) {
        content = props?["content"]?.stringValue
        // `Int(exactly:)` returns nil for fractions and out-of-range
        // values. `Int(someDouble)` would trap on a huge number, and
        // `props` comes from the network, so it must never trap.
        lineLimit = props?["numberOfLines"]?.numberValue
                   .flatMap { Int(exactly: $0) }
                   .flatMap { $0 > 0 ? $0 : nil }
    }
}

/// Renders `type: "text"`
///  Handles typography only: content, font, color and line limit. Box styling (padding, background, radius, border) is applied centrally for every node type, not per renderer. That arrives in the next piece.
public struct TextNodeRenderer: NodeRenderer {
    public init() {}
    public func makeView(for node: SDUISchema.Node, context: RenderContext) -> AnyView {
        let props = TextProps(node.props)
        /// No content means nothing to show. Render nothing rather than an empty Text, which would still take up stack spacing.
        guard let content = props.content else {
            return AnyView(EmptyView())
        }
        let style = ResolvedStyle.resolve(
            node.style,
            using: context.theme
        )
        let text = Text(content).font(style.font)
        let colored = style.textColor.map { text.foregroundColor($0) } ?? text
        return AnyView(colored.lineLimit(props.lineLimit))
    }
}
