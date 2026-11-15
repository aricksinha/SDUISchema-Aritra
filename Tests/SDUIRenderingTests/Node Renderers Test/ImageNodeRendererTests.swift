//
//  ImageNodeRendererTests.swift
//  
//
//  Created by Aritra on 15/11/26.
//

import XCTest
import SwiftUI
import SDUISchema
import SDUIDesignSystem
@testable import SDUIRendering

private final class StubImageProvider: RemoteImageViewProviding {
    private(set) var requestedURL: URL?
    private(set) var requestedMode: ImageContentMode?
    func makeImageView(url: URL, contentMode: ImageContentMode) -> AnyView {
        requestedURL = url
        requestedMode = contentMode
        return AnyView(EmptyView())
    }
}

final class ImagePropsTests: XCTestCase {
    func test_url_parsesValid_andFailsClosedOnMissingOrGarbage() {
        XCTAssertEqual(ImageProps(.object(["url": .string("https://a.com/x.png")])).url,
                       URL(string: "https://a.com/x.png"))
        XCTAssertNil(ImageProps(nil).url)
        XCTAssertNil(ImageProps(.object(["url": .number(42)])).url)
    }

    func test_contentMode_defaultsToFit_forMissingOrUnknown() {
        XCTAssertEqual(ImageProps(.object([:])).contentMode, .fit)
        XCTAssertEqual(ImageProps(.object(["contentMode": .string("nonsense")])).contentMode, .fit)
        XCTAssertEqual(ImageProps(.object(["contentMode": .string("fill")])).contentMode, .fill)
    }
}

final class ImageNodeRendererTests: XCTestCase {
    private let ctx = RenderContext(theme: StaticTheme.placeholder) { _ in AnyView(EmptyView()) }
    
    func test_validURL_isPassedToTheProvider_withContentMode() {
        let stub = StubImageProvider()
        let node = Node(id: "i", type: "image",
                        props: .object(["url": .string("https://a.com/x.png"), "contentMode": .string("fill")]))
        
        _ = ImageNodeRenderer(provider: stub).makeView(for: node, context: ctx)
        
        XCTAssertEqual(stub.requestedURL, URL(string: "https://a.com/x.png"))
        XCTAssertEqual(stub.requestedMode, .fill)
    }
    
    func test_missingURL_rendersWithoutCallingTheProvider() {
        let stub = StubImageProvider()
        _ = ImageNodeRenderer(provider: stub).makeView(for: Node(id: "i", type: "image"), context: ctx)
        XCTAssertNil(stub.requestedURL)
    }
}
