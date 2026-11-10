//
//  StaticTheme.swift
//
//
//  Created by Aritra on 10/11/26.
//

import SwiftUI

/// The default `Theme` conformance most host apps will actually use:  a fixed catalog of token → value mappings, built once (typically  from the app's existing design system constants) and handed to  the Composition Root at launch.
/// /// Internally stores `[Token<Category>: Value]` dictionaries rather than anything fancier — this is exactly why `Token` was made `Hashable` earlier. Lookup is a plain dictionary hit,  O(1); there is no "cache" to build here, because a dictionary literally is one. (A theme that computes values on the fly — e.g. deriving a pressed-state tint — is where a real memoization cache earns its keep; see the note at the bottom.)
public struct StaticTheme: Theme {
    private let colors: [ColorToken: Color]
    private let fonts: [FontToken: Font]
    private let spacings: [SpacingToken: CGFloat]
    private let radii: [RadiusToken: CGFloat]
    
    public init(
        colors: [ColorToken: Color] = [:],
        fonts: [FontToken: Font] = [:],
        spacings: [SpacingToken: CGFloat] = [:],
        radii: [RadiusToken: CGFloat] = [:]
    ) {
        self.colors = colors
        self.fonts = fonts
        self.spacings = spacings
        self.radii = radii
    }
    
    func color(for token: ColorToken) -> Color { colors[token] ?? .clear }
    func font(for token: FontToken) -> Font { fonts[token] ?? .body }
    func spacing(for token: SpacingToken) -> CGFloat { spacings[token] ?? 0 }
    func radius(for token: RadiusToken) -> CGFloat { radii[token] ?? 0 }
}

/// A minimal starter catalog so the SDK renders something sane out
/// of the box, before a host app supplies its own brand theme.
// TODO : - Don't ship this in real app - it exists so `SDUIRendering` previews/tests don't require a bespoke `Theme` just to render a fixture, and so a first integration has something to look at before the design-token conversation with the design team happens.

public extension StaticTheme {
    static let placeholder = StaticTheme(
        colors: [
            "surfacePrimary": Color(white: 1.0),
            "surfaceSecondary": Color(white: 0.95),
            "textPrimary": Color(white: 0.1),
            "textSecondary": Color(white: 0.4),
            "accent": .blue
        ],
        fonts: [
            "titleLarge": .title,
            "body": .body,
            "caption": .caption
        ],
        spacings: [
            "spacingSm": 4,
            "spacingMd": 8,
            "spacingLg": 16
        ],
        radii: [
            "radiusSm": 4,
            "radiusMd": 8,
            "radiusLg": 16
        ]
    )
}
