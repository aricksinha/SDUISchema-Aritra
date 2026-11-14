//
//  NodeViewFactoryTest.swift
//  
//
//  Created by Aritra on 13/11/26.
//

import XCTest
import SwiftUI
import SDUISchema
import SDUIDesignSystem
@testable import SDUIRendering

/// A reference type so the protocol's non-mutating `makeView` can
/// record what it was asked to render. It forces its children to
/// render through the context, the way a real container does.
private final class RecordingRenderer: NodeRenderer {
    private(set) var rendered: [String] = []

    func makeView(for node: Node, context: RenderContext) -> AnyView {
        rendered.append(node.id)
        _ = context.childViews(of: node)
        return AnyView(EmptyView())
    }
}

final class NodeViewFactoryTests: XCTestCase {

    private func makeRegistry(recording: RecordingRenderer) -> RendererRegistry {
        var registry = RendererRegistry(fallback: UnknownNodePlaceholder(showsDiagnostics: false))
        registry.register(recording, for: "container")
        return registry
    }

    func test_children_renderThroughTheRegistry_inOrder() {
        let recorder = RecordingRenderer()
        let root = Node(id: "root", type: "container", children: [
            .node(Node(id: "a", type: "container")),
            .node(Node(id: "b", type: "container"))
        ])

        _ = makeNodeView(root, theme: StaticTheme.placeholder, registry: makeRegistry(recording: recorder))

        XCTAssertEqual(recorder.rendered, ["root", "a", "b"])
    }

    func test_quarantinedChild_isSkipped_andUnknownTypeDoesNotCrash() {
        let recorder = RecordingRenderer()
        let root = Node(id: "root", type: "container", children: [
            .node(Node(id: "a", type: "container")),
            .failed(DecodeFailure(nodeID: nil, nodeType: nil, reason: "broken")),
            .node(Node(id: "mystery", type: "x-unknown")),
            .node(Node(id: "b", type: "container"))
        ])

        _ = makeNodeView(root, theme: StaticTheme.placeholder, registry: makeRegistry(recording: recorder))

        XCTAssertEqual(
            recorder.rendered, ["root", "a", "b"],
            "the failed slot is skipped, the unknown type goes to the fallback, and siblings still render"
        )
    }

    func test_sduiView_withUnknownRootType_buildsWithoutCrashing() {
        let screen = Screen(screenID: "s", structureVersion: 1, root: Node(id: "root", type: "x-unknown"))
        let view = SDUIView(
            screen: screen,
            theme: StaticTheme.placeholder,
            registry: RendererRegistry(fallback: UnknownNodePlaceholder(showsDiagnostics: false))
        )

        _ = view.body
    }
}
