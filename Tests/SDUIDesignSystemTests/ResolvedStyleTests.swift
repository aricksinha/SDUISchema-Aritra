//
//  ResolvedStyleTests.swift
//
//
//  Created by Aritra on 11/11/26.
//

import XCTest
import SwiftUI
import SDUISchema
@testable import SDUIDesignSystem

final class ResolvedStyleTests: XCTestCase {
    func test_resolve_mapsEachTokenThroughTheTheme() {
        let theme = StaticTheme(
            colors: ["bg": .red, "text": .black],
            fonts: ["title": .title],
            spacings: ["md": 8],
            radii: ["sm": 4]
        )
        let styleRef = StyleRef(
            backgroundColorToken: "bg",
            textColorToken: "text",
            fontToken: "title",
            paddingToken: "md",
            radiusToken: "sm"
        )

        let resolved = ResolvedStyle.resolve(styleRef, using: theme)

        XCTAssertEqual(resolved.backgroundColor, .red)
        XCTAssertEqual(resolved.textColor, Color.black)
        XCTAssertEqual(resolved.padding, 8)
        XCTAssertEqual(resolved.radius, 4)
    }

    func test_resolve_nilStyleRef_fallsBackEverywhere() {
        let resolved = ResolvedStyle.resolve(nil, using: StaticTheme())
        XCTAssertEqual(resolved.backgroundColor, .clear)
        XCTAssertEqual(resolved.padding, 0)
        XCTAssertNil(resolved.textColor)
    }
}
