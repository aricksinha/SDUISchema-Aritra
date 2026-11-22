//
//  SDUIView.swift
//
//
//  Created by Aritra on 13/11/26.
//

import SwiftUI
import SDUISchema
import SDUIDesignSystem

public struct SDUIView: View {
    private let screen: Screen
    private let theme: Theme
    private let registry: RendererRegistry
    /// expose onAction
    private let onAction: (String) -> Void
    
    public init(
        screen: Screen,
        theme: Theme,
        registry: RendererRegistry,
        onAction: @escaping (String) -> Void = { _ in }) {
            self.screen = screen
            self.theme = theme
            self.registry = registry
            self.onAction = onAction
    }
    
    public var body: some View {
        makeNodeView(
            screen.root,
            theme: theme,
            registry: registry,
            onAction: onAction
        )
    }
}
