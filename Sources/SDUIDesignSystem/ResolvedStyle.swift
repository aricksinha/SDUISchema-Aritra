//
//  ResolvedStyle.swift
//
//
//  Created by Aritra on 11/11/26.
//


import SwiftUI
import SDUISchema

/// Converts a `StyleRef`/`Layout` — the OPEN, untyped token-name
/// strings that arrived over the wire — into a bundle of concrete,
/// already-resolved SwiftUI values, using a given `Theme`.
///
/// This struct is the one and only place a raw `String` from`SDUISchema` becomes a `Token<Category>`. Every node renderer in`SDUIRendering` consumes a `ResolvedStyle`, never a `StyleRef`  directly — so a renderer never touches `Theme` or a raw token string its is exactly what keeps renderers trivial to unit test with fixed inputs instead of a live `Theme`.
public struct ResolvedStyle: Equatable {
    public let backgroundColor: Color
    public let textColor: Color
    public let font: Font
    public let padding: CGFloat
    public let radius: CGFloat
    public let borderColor: Color

    public static func resolve(_ styleRef: StyleRef?, using theme: Theme) -> ResolvedStyle {
        ResolvedStyle(
            backgroundColor: theme.color(for: styleRef?.backgroundColorToken.map { ColorToken($0) }),
            textColor: theme.color(for: styleRef?.textColorToken.map { ColorToken($0) }),
            font: theme.font(for: styleRef?.fontToken.map { FontToken($0) }),
            padding: theme.spacing(for: styleRef?.paddingToken.map { SpacingToken($0) }),
            radius: theme.radius(for: styleRef?.radiusToken.map { RadiusToken($0) }),
            borderColor: theme.color(for: styleRef?.borderColorToken.map { ColorToken($0) })
        )
    }
}
