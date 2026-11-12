//
//  ResolvedLayoutTests.swift
//  
//
//  Created by Aritra on 12/11/26.
//

import XCTest
import SDUISchema
@testable import SDUIDesignSystem

final class ResolvedLayoutTests: XCTestCase {
    func test_resolve_mapsSpacingTokenThroughTheTheme() {
        let theme = StaticTheme(spacings: ["spacingMd": 8])
        let layout = Layout(
            direction: .horizontal,
            alignment: .center,
            spacingToken: "spacingMd",
            weight: 2
        )
        let resolved = ResolvedLayout.resolve(layout, using: theme)
        XCTAssertEqual(resolved.direction, .horizontal)
        XCTAssertEqual(resolved.alignment, .center)
        XCTAssertEqual(resolved.spacing, 8)
        XCTAssertEqual(resolved.weight, 2)
    }
    
    func test_resolve_unknownSpacingToken_fallsBackToZero() {
        let layout = Layout(direction: .vertical, spacingToken: "doesNotExist")
        let resolved = ResolvedLayout.resolve(layout, using: StaticTheme())
        XCTAssertEqual(resolved.spacing, 0)
    }
    
    func test_resolve_nilLayout_degradesToVerticalWithNoSpacing() {
        let resolved = ResolvedLayout.resolve(nil, using: StaticTheme())
        
        XCTAssertEqual(resolved.direction, .vertical)
        XCTAssertNil(resolved.alignment)
        XCTAssertEqual(resolved.spacing, 0)
        XCTAssertNil(resolved.weight)
    }
}
