//
//  ResolvedLayout.swift
//
//
//  Created by Aritra on 12/11/26.
//

import SwiftUI
import SDUISchema

/// The layout counterpart to `ResolvedStyle`. Only `spacingToken` is
/// an open-vocabulary string that needs a `Theme` to resolve.
/// `direction`, `alignment` and `weight` come from closed sets (or are
/// plain numbers), so they pass through unchanged.

/// /// Renderers consume this instead of `Layout`, so they never touch a
/// `Theme` or a raw token string directly.
public struct ResolvedLayout: Equatable {
    public let direction: SDUISchema.Layout.Direction
    public let alignment: SDUISchema.Layout.Alignment?
    public let spacing: CGFloat
    
    /// `nil` means intrinsic sizing. Deliberately not defaulted to a number, so renderers can tell "no weight specified" apart from any real value.
    public let weight: Double?
    
    public static func resolve(
        _ layout: SDUISchema.Layout?,
        using theme: Theme
    ) -> ResolvedLayout {
        ResolvedLayout(
            /// A missing layout degrades to a plain vertical stack, the  safest default. It mirrors "optional fields degrade, never throw".
            direction: layout?.direction ?? .vertical,
            alignment: layout?.alignment,
            spacing: theme.spacing(for: layout?.spacingToken.map { SpacingToken($0) }),
            weight: layout?.weight
        )
    }
}
