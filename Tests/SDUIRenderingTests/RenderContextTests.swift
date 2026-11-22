//
//  RenderContextTests.swift
//  
//
//  Created by Aritra on 13/11/26.
//

import XCTest
import SDUISchema
import SDUIDesignSystem
@testable import SDUIRendering
import SwiftUI

final class RenderContextTests: XCTestCase {

    func test_render_delegatesToTheInjectedClosure() {
        var rendered: [String] = []
        let context = RenderContext(theme: StaticTheme.placeholder) { node in
            rendered.append(node.id)
            return AnyView(EmptyView())
        }
        
        _ = context.render(Node(id: "a", type: "text"))
        
        XCTAssertEqual(rendered, ["a"])
    }
    
    func test_childViews_skipsQuarantinedSlots_andKeepsDataDerivedIdentity() {
        let parent = Node(
            id: "parent",
            type: "stack",
            children: [
                .node(Node(id: "first", type: "text")),
                .failed(DecodeFailure(nodeID: nil, nodeType: nil, reason: "broken")),
                .node(Node(id: "second", type: "text"))
            ]
        )
        let context = RenderContext(theme: StaticTheme.placeholder) { _ in AnyView(EmptyView()) }
        
        let children = context.childViews(of: parent)
        
        XCTAssertEqual(children.map(\.id), ["first", "second"])
    }
    
    func test_dispatch_forwardsActionIDToTheClosure() {
        var received: [String] = []
        let context = RenderContext(
            theme: StaticTheme.placeholder,
            renderNode: { _ in AnyView(EmptyView()) },
            dispatchAction: { received.append($0) }
        )
        context.dispatch(actionID: "checkout")
        XCTAssertEqual(received, ["checkout"])
    }
}
