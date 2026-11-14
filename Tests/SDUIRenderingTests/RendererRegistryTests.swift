//
//  RendererRegistryTests.swift
//
//
//  Created by Aritra on 13/11/26.
//

import XCTest
import SwiftUI
import SDUISchema
@testable import SDUIRendering

private struct StubRenderer: NodeRenderer {
    let name: String
    func makeView(for node: Node, context: RenderContext) -> AnyView {
        AnyView(EmptyView())
    }
}

final class RendererRegistryTests: XCTestCase {
    
    func test_registeredType_resolvesToItsRenderer() {
        var registry = RendererRegistry()
        registry.register(StubRenderer(name: "text"), for: "text")
        
        let resolved = registry.renderer(for: "text") as? StubRenderer
        XCTAssertEqual(resolved?.name, "text")
    }
    
    func test_unregisteredType_resolvesToTheFallback_neverNilNeverCrashes() {
        let registry = RendererRegistry()
        
        XCTAssertTrue(registry.renderer(for: "x-neverHeardOfIt") is UnknownNodePlaceholder)
    }
    
    func test_registeringTheSameTypeTwice_lastRegistrationWins() {
        var registry = RendererRegistry()
        registry.register(StubRenderer(name: "builtin"), for: "text")
        registry.register(StubRenderer(name: "override"), for: "text")
        
        let resolved = registry.renderer(for: "text") as? StubRenderer
        
        XCTAssertEqual(resolved?.name, "override")
    }
    
    func test_lookupIsCaseSensitive() {
        var registry = RendererRegistry()
        registry.register(StubRenderer(name: "text"), for: "text")
        
        XCTAssertTrue(registry.renderer(for: "Text") is UnknownNodePlaceholder)
    }
    
    func test_customFallback_isUsedForUnknownTypes() {
        let registry = RendererRegistry(fallback: StubRenderer(name: "custom-fallback"))
        
        let resolved = registry.renderer(for: "anything") as? StubRenderer
        
        XCTAssertEqual(resolved?.name, "custom-fallback")
    }
}
