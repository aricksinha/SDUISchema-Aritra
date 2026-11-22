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
    let borderWidth: CGFloat?

    static func resolve(_ style: StyleRef?, using theme: Theme) -> BoxStyle? {
        guard let style else { return nil }
        let box = BoxStyle(
            padding: style.paddingToken.map { theme.spacing(for: SpacingToken($0)) },
            backgroundColor: style.backgroundColorToken.map { theme.color(for: ColorToken($0)) },
            cornerRadius: style.radiusToken.map { theme.radius(for: RadiusToken($0)) },
            borderColor: style.borderColorToken.map { theme.color(for: ColorToken($0)) },
            borderWidth: style.borderWidthToken.map { theme.borderWidth(for: BorderWidthToken($0)) }
        )
        return box.isEmpty ? nil : box
    }

    var isEmpty: Bool {
        padding == nil && backgroundColor == nil && cornerRadius == nil
            && borderColor == nil && borderWidth == nil
    }
}

struct BoxStyleModifier: ViewModifier {
    let box: BoxStyle

    /// Used when the server sets a border color but no width token, so
    /// payloads written before `borderWidthToken` existed look the same.
    static let defaultBorderWidth: CGFloat = 1

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: box.cornerRadius ?? 0, style: .continuous)
        content
            .padding(box.padding ?? 0)
            .background(box.backgroundColor ?? .clear, in: shape)
            .overlay {
                if let borderColor = box.borderColor {
                    shape.strokeBorder(borderColor, lineWidth: box.borderWidth ?? Self.defaultBorderWidth)
                }
            }
    }
}
