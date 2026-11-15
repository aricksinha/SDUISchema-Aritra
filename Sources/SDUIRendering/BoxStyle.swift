//
//  BoxStyle.swift
//
//
//  Created by Aritra on 14/11/26.
//

import SwiftUI
import SDUISchema
import SDUIDesignSystem

/// The "box" part of a node's style: padding, background, corner radius and border.
///
/// Applied once, centrally, in `makeNodeView`, so every component gets it and no renderer has to remember to. Renderers keep handling only what is specific to them (for text: font, color, line limit).
/// Each field is optional and means "the server specified this." That's why this resolves from `StyleRef` directly rather than from `ResolvedStyle`, whose fallbacks (`.clear`, `0`) can't distinguish "not specified" from "specified as nothing."
struct BoxStyle: Equatable {
    let padding: CGFloat?
    let backgroundColor: Color?
    let cornerRadius: CGFloat?
    let borderColor: Color?
    
    static func resolve(_ style: StyleRef?, using theme: Theme) -> BoxStyle? {
        guard let style else { return nil }
        let box = BoxStyle(
            padding: style.paddingToken.map { theme.spacing(for: SpacingToken($0)) },
            backgroundColor: style.backgroundColorToken.map { theme.color(for: ColorToken($0)) },
            cornerRadius: style.radiusToken.map { theme.radius(for: RadiusToken($0)) },
            borderColor: style.borderColorToken.map { theme.color(for: ColorToken($0)) }
        )
        return box.isEmpty ? nil : box
    }
    
    var isEmpty: Bool {
        padding == nil && backgroundColor == nil && cornerRadius == nil && borderColor == nil
    }
}

/// Applies a `BoxStyle`. Order matters: padding first, so the background and border surround the padded content, not the bare content.
/// The radius shapes the background and border but does NOT clip the content. Clipping would cut off overflowing content and shadows.Components that need clipping, like images, do it themselves.
struct BoxStyleModifier: ViewModifier {
    let box: BoxStyle
    
    /// no border width token yet  so a border is always 1pt.If design needs variable widths, that's a new `StyleRef` field,which is an additive, non-breaking change.
    private let borderWidth: CGFloat = 1

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: box.cornerRadius ?? 0, style: .continuous)
        content
            .padding(box.padding ?? 0)
            .background(box.backgroundColor ?? .clear, in: shape)
            .overlay {
                if let borderColor = box.borderColor {
                    shape.strokeBorder(borderColor, lineWidth: borderWidth)
                }
            }
    }
}
