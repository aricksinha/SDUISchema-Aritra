//
//  SDUIView.swift
//
//
//  Created by Aritra on 13/11/26.
//

import SwiftUI
import SDUISchema
import SDUIDesignSystem

struct SDUIView: View {
    private let screen: Screen
    private let theme: Theme
    private let registry: RendererRegistry
    
    public init(screen: Screen, theme: Theme, registry: RendererRegistry) {
        self.screen = screen
        self.theme = theme
        self.registry = registry
    }
    
    public var body: some View {
        makeNodeView(screen.root, theme: theme, registry: registry)
    }
}
