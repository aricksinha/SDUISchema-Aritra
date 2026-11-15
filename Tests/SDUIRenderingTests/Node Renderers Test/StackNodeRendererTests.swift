//
//  StackNodeRendererTests.swift
//
//
//  Created by Aritra on 14/11/26.
//

import XCTest
import SwiftUI
import SDUISchema
import SDUIDesignSystem
@testable import SDUIRendering

final class StackAlignmentTests: XCTestCase {

    // Vertical stack → HorizontalAlignment (cross-axis)
    func test_horizontal_mapsOnAxisValues_andDegradesOffAxisToCenter() {
        XCTAssertEqual(StackAlignment.horizontal(.leading), .leading)
        XCTAssertEqual(StackAlignment.horizontal(.trailing), .trailing)
        for offAxis: SDUISchema.Layout.Alignment in [.center, .top, .bottom] {
            XCTAssertEqual(StackAlignment.horizontal(offAxis), .center)
        }
        XCTAssertEqual(StackAlignment.horizontal(nil), .center)
    }

    // Horizontal stack → VerticalAlignment (cross-axis)
    func test_vertical_mapsOnAxisValues_andDegradesOffAxisToCenter() {
        XCTAssertEqual(StackAlignment.vertical(.top), .top)
        XCTAssertEqual(StackAlignment.vertical(.bottom), .bottom)
        for offAxis: SDUISchema.Layout.Alignment in [.center, .leading, .trailing] {
            XCTAssertEqual(StackAlignment.vertical(offAxis), .center)
        }
        XCTAssertEqual(StackAlignment.vertical(nil), .center)
    }

    // Overlay → Alignment (every value applies)
    func test_overlay_mapsEveryValue() {
        XCTAssertEqual(StackAlignment.overlay(.leading), .leading)
        XCTAssertEqual(StackAlignment.overlay(.trailing), .trailing)
        XCTAssertEqual(StackAlignment.overlay(.top), .top)
        XCTAssertEqual(StackAlignment.overlay(.bottom), .bottom)
        XCTAssertEqual(StackAlignment.overlay(.center), .center)
        XCTAssertEqual(StackAlignment.overlay(nil), .center)
    }
}

final class StackNodeRendererTests: XCTestCase {

    private func recordingContext(_ recorder: @escaping (String) -> Void) -> RenderContext {
        RenderContext(theme: StaticTheme.placeholder) { node in
            recorder(node.id)
            return AnyView(EmptyView())
        }
    }

    func test_rendersHealthyChildrenInOrder_skippingQuarantinedSlots() {
        var rendered: [String] = []
        let stack = Node(id: "stack", type: "stack",
            layout: SDUISchema.Layout(direction: .vertical),
            children: [
                .node(Node(id: "a", type: "text")),
                .failed(DecodeFailure(nodeID: nil, nodeType: nil, reason: "broken")),
                .node(Node(id: "b", type: "text"))
            ])

        _ = StackNodeRenderer().makeView(for: stack, context: recordingContext { rendered.append($0) })

        XCTAssertEqual(rendered, ["a", "b"])
    }

    func test_buildsAView_forEveryDirection_withoutCrashing() {
        for direction: SDUISchema.Layout.Direction in [.vertical, .horizontal, .overlay] {
            let stack = Node(id: "s", type: "stack",
                layout: SDUISchema.Layout(direction: direction),
                children: [.node(Node(id: "c", type: "text"))])
            _ = StackNodeRenderer().makeView(for: stack, context: recordingContext { _ in })
        }
    }

    func test_missingLayout_degradesToVertical_withoutCrashing() {
        let stack = Node(id: "s", type: "stack", children: [.node(Node(id: "c", type: "text"))])
        _ = StackNodeRenderer().makeView(for: stack, context: recordingContext { _ in })
    }
}
