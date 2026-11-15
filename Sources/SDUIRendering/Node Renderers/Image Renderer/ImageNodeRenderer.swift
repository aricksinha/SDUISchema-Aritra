//
//  ImageNodeRenderer.swift
//
//
//  Created by Aritra on 15/11/26.
//

import SwiftUI
import SDUISchema

/// The typed view of an image node's `props`. Reads never throw; everything degrades to a safe default.
struct ImageProps: Equatable {
    let url: URL?
    let contentMode: ImageContentMode
    
    init(_ props: JSONValue?) {
        url = props?["url"]?.stringValue.flatMap(URL.init(string:))
        
        switch props?["contentMode"]?.stringValue {
        case "fill": contentMode = .fill
        default: contentMode = .fit   /// missing, unknown, or "fit" all land here
        }
    }
}

/// Renders `type: "image"`. Loading is delegated to the injected provider, so this type stays tiny and has no opinion about caching.
public struct ImageNodeRenderer: NodeRenderer {
    private let provider: RemoteImageViewProviding
    
    public init(provider: RemoteImageViewProviding) {
        self.provider = provider
    }
    
    public func makeView(for node: Node, context: RenderContext) -> AnyView {
        /// A missing or malformed URL renders nothing rather than a broken-image box — same fail-closed stance as everywhere else.
        guard let url = ImageProps(node.props).url else { return AnyView(EmptyView()) }
        return provider.makeImageView(url: url, contentMode: ImageProps(node.props).contentMode)
    }
}
