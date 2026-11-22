//
//  TapActionModifier.swift
//  
//
//  Created by Aritra on 21/11/26.
//

import SwiftUI

/// Makes a whole node tappable. Applied in `makeNodeView` OUTSIDE
/// `BoxStyle`, so the padded area is part of the tap target.
struct TapActionModifier: ViewModifier {
    let actionID: String
    let dispatch: (String) -> Void

    func body(content: Content) -> some View {
        content
            .contentShape(Rectangle())
            .onTapGesture { dispatch(actionID) }
            .accessibilityAddTraits(.isButton)
    }
}
