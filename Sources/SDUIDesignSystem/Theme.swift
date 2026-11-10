//
//  Theme.swift
//
//
//  Created by Aritra on 10/11/26.
//

import SwiftUI

/// - ** Theme Protocol ** - resolves tokens to real values, plus the resolution cache.
/// why Theme shouldn't be sing;e concreate struct?
/// - coz a struct bakes in “a theme is always a static in-memory dictionary,” which forecloses a theme backed by a remote config fetch, or one that computes values (e.g., deriving a pressed-state color from a base color at resolve time) instead of storing them
/// - A protocol keeps that open, the same Open/Closed instinct as the NodeRenderer registry.

/// - ** Protocol Description **
/// - ONLY place in the whole SDK that is allowed to know what a `ColorToken` actually looks like on screen.
/// - `SDUISchema` never sees a `Color`; `SDUIRendering`'s node renderers never see  a raw token string — they ask a `Theme` to resolve one.
/// A protocol, not a struct, deliberately: a host app's theme might be a static catalog (the common case, see `StaticTheme` below),  or it might be backed by a remote-config fetch, computed light/dark variants, or per-tenant overrides for a white-label app. All of those are just other conformances — nothing else in
/// the SDK needs to change to support them.
public protocol Theme {
    func color(for token: ColorToken) -> Color
    func font(for token: FontToken) -> Font
    func spacing(for token: SpacingToken) -> CGFloat
    func radius(for token: RadiusToken) -> CGFloat
}

/// Every method gets a fallback so an unresolvable token — a name  the server sent that this theme doesn't define, which WILL  happen given that token names are an open, ever-growing vocabulary on the wire — degrades to something

public extension Theme {
    func color(for token: ColorToken?) -> Color {
        token.map(color(for:)) ?? .clear
    }
    func font(for token: FontToken?) -> Font {
        token.map(font(for:)) ?? .body
    }
    func spacing(for token: SpacingToken?) -> CGFloat {
        token.map(spacing(for:)) ?? 0
    }
    func radius(for token: RadiusToken?) -> CGFloat {
        token.map(radius(for:)) ?? 0
    }
}
