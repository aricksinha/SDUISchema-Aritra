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
            BoxStyle(padding: 8, backgroundColor: .red, cornerRadius: 4, borderColor: .blue, borderWidth: nil)
        )
    }

    func test_onlySpecifiedFields_areSet() {
        XCTAssertEqual(
            BoxStyle.resolve(StyleRef(paddingToken: "md"), using: theme),
            BoxStyle(padding: 8, backgroundColor: nil, cornerRadius: nil, borderColor: nil, borderWidth: nil)
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
    
    func test_resolve_borderWidth_isNilWhenNotSpecified_andResolvedWhenSpecified() {
        let theme = StaticTheme(colors: ["accent": .blue], borderWidths: ["thick": 3])

        let colorOnly = BoxStyle.resolve(StyleRef(borderColorToken: "accent"), using: theme)
        XCTAssertNil(colorOnly?.borderWidth)

        let withWidth = BoxStyle.resolve(StyleRef(borderColorToken: "accent", borderWidthToken: "thick"), using: theme)
        XCTAssertEqual(withWidth?.borderWidth, 3)
    }

    func test_resolve_widthTokenAlone_isNotEmpty_butTypographyOnlyIs() {
        let theme = StaticTheme(borderWidths: ["thick": 3])
        XCTAssertNotNil(BoxStyle.resolve(StyleRef(borderWidthToken: "thick"), using: theme))
        XCTAssertNil(BoxStyle.resolve(StyleRef(fontToken: "body"), using: theme))
    }
}
