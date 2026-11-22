//
//  ButtonNodeRendererTests.swift
//  
//
//  Created by Aritra on 21/11/26.
//

import XCTest
import SwiftUI
import SDUISchema
import SDUIDesignSystem
@testable import SDUIRendering

final class ButtonNodeRendererTests: XCTestCase {
    private let ctx = RenderContext(theme: StaticTheme.placeholder) { _ in AnyView(EmptyView()) }

    func test_buildsForEachLabelAndActionCase_withoutCrashing() {
        let withTitle = Node(id: "a", type: "button", actionID: "x", props: .object(["title": .string("Buy")]))
        let withIconAndTitle = Node(
            id: "icon",
            type: "button",
            actionID: "x",
            props: .object(["title": .string("Buy"), "systemImage": .string("cart.fill")])
        )
        let withChildren = Node(id: "b", type: "button", children: [.node(Node(id: "c", type: "text", props: .object(["content": .string("Go")])))], actionID: "x")
        let noAction = Node(id: "d", type: "button", props: .object(["title": .string("Inert")]))
        let empty = Node(id: "e", type: "button")

        for node in [withTitle, withIconAndTitle, withChildren, noAction, empty] {
            _ = ButtonNodeRenderer().makeView(for: node, context: ctx)
        }
    }
}
