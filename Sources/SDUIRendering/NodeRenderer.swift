//
//  NodeRenderer.swift
//
//
//  Created by Aritra on 13/11/26.
//

import SwiftUI
import SDUISchema

/// One implementation per node `type` (text, stack, card, ...).  New components are new conformances registered with the registry. Nothing existing changes
/// A renderer's whole job is: take a node, resolve its style & layout against `context.theme`, and return a view.It shouldn't know about analytics, accessibility or the registry. ** Decorators ** handle 1st two & the context closure handles recursion.
public protocol NodeRenderer {
    func makeView(for node: Node, context: RenderContext) -> AnyView
}
