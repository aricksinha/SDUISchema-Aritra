//
//  BoxStyleTests.swift
//  
//
//  Created by Aritra on 14/11/26.
//

import XCTest
import SwiftUI
import SDUISchema
import SDUIDesignSystem
@testable import SDUIRendering

final class BoxStyleTests: XCTestCase {
    private let theme = StaticTheme(
        colors: ["bg": .red, "line": .blue],
        spacings: ["md": 8],
        radii: ["sm": 4]
    )

    func test_nilStyle_hasNoBox() {
        XCTAssertNil(BoxStyle.resolve(nil, using: theme))
    }

    func test_typographyOnlyStyle_hasNoBox() {
        let style = StyleRef(textColorToken: "accent", fontToken: "titleLarge")
        XCTAssertNil(BoxStyle.resolve(style, using: theme))
    }

    func test_boxTokens_resolveThroughTheTheme() {
        let style = StyleRef(
            backgroundColorToken: "bg",
            paddingToken: "md",
            radiusToken: "sm",
            borderColorToken: "line"
        )
        XCTAssertEqual(
            BoxStyle.resolve(style, using: theme),
            BoxStyle(padding: 8, backgroundColor: .red, cornerRadius: 4, borderColor: .blue)
        )
    }

    func test_onlySpecifiedFields_areSet() {
        XCTAssertEqual(
            BoxStyle.resolve(StyleRef(paddingToken: "md"), using: theme),
            BoxStyle(padding: 8, backgroundColor: nil, cornerRadius: nil, borderColor: nil)
        )
    }

    func test_unknownTokenNames_degradeToThemeFallbacks_neverCrash() {
        let box = BoxStyle.resolve(
            StyleRef(backgroundColorToken: "nope", paddingToken: "nope"),
            using: theme
        )
        XCTAssertEqual(box?.padding, 0)
        XCTAssertEqual(box?.backgroundColor, .clear)
    }
}
