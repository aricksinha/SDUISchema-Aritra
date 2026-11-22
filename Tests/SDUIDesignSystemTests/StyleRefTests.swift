//
//  StyleRefTests.swift
//  
//
//  Created by Aritra on 21/11/26.
//

import XCTest
@testable import SDUISchema

final class StyleRefTests: XCTestCase {
    func test_decodesBorderWidthToken_andAbsenceIsNil() throws {
        let with = try JSONDecoder().decode(StyleRef.self, from: Data(#"{"borderWidthToken":"thin"}"#.utf8))
        XCTAssertEqual(with.borderWidthToken, "thin")

        let without = try JSONDecoder().decode(StyleRef.self, from: Data("{}".utf8))
        XCTAssertNil(without.borderWidthToken)
    }
}
