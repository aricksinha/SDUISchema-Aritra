//
//  NodeTapTest.swift
//  
//
//  Created by Aritra on 21/11/26.
//

import XCTest
@testable import SDUIRendering

final class NodeTapTests: XCTestCase {
    func test_containersAndText_getTheNodeTap() {
        XCTAssertTrue(StackNodeRenderer().appliesNodeTapAction)
        XCTAssertTrue(TextNodeRenderer().appliesNodeTapAction)
    }

    func test_button_handlesItsOwnTap_andUnknownNodesNeverFireActions() {
        XCTAssertFalse(ButtonNodeRenderer().appliesNodeTapAction)
        XCTAssertFalse(UnknownNodePlaceholder().appliesNodeTapAction)
    }
}
