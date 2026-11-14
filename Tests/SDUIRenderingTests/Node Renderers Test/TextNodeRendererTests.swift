//
//  TextNodeRendererTests.swift
//  
//
//  Created by Aritra on 14/11/26.
//

import XCTest
import SwiftUI
import SDUISchema
import SDUIDesignSystem
@testable import SDUIRendering

final class TextNodeRendererTests: XCTestCase {

    func test_content_isReadFromProps() {
        let props = TextProps(.object(["content": .string("hello")]))
        XCTAssertEqual(props.content, "hello")
    }
    
    func test_missingOrNonStringContent_isNil() {
        XCTAssertNil(TextProps(nil).content)
        XCTAssertNil(TextProps(.object([:])).content)
        XCTAssertNil(TextProps(.object(["content": .number(42)])).content)
    }
    
    func test_numberOfLines_acceptsAPositiveInteger() {
        let props = TextProps(.object(["content": .string("x"), "numberOfLines": .number(2)]))
        XCTAssertEqual(props.lineLimit, 2)
    }
    
    func test_numberOfLines_rejectsZero_negative_fractional_andHugeValues() {
        for bad in [0.0, -1.0, 2.5, 1e30] {
            let props = TextProps(.object(["numberOfLines": .number(bad)]))
            XCTAssertNil(props.lineLimit, "\(bad) must degrade to nil, never trap")
        }
    }
    
    func test_rendererBuildsAView_forMissingContent_andMissingProps_withoutCrashing() {
           let context = RenderContext(theme: StaticTheme.placeholder) { _ in AnyView(EmptyView()) }
           let renderer = TextNodeRenderer()

           _ = renderer.makeView(for: Node(id: "a", type: "text"), context: context)
           _ = renderer.makeView(for: Node(id: "b", type: "text", props: .object(["content": .string("Hi")])), context: context)
       }
}
