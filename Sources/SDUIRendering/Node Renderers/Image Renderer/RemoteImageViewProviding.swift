//
//  RemoteImageViewProviding.swift
//
//
//  Created by Aritra on 15/11/26.
//

import SwiftUI

/// the renderer must not hardcode AsyncImage. Real host apps already have an image stack (Kingfisher, Nuke, SDWebImage) with their own caching, and an SDK that forces AsyncImage can’t integrate with it.
/// Injected into `ImageNodeRenderer`at the Composition Root so a host app can plug in its existing image stack (Kingfisher, Nuke, SDWebImage) with its own caching, instead of the SDK dictating one. The SDK ships a working default; production apps usually swap it.
public protocol RemoteImageViewProviding {
    func makeImageView(url: URL, contentMode: ImageContentMode) -> AnyView
}

/// Closed set — maps to SwiftUI's `ContentMode`.
public enum ImageContentMode {
    case fit, fill
    var swiftUI: ContentMode { self == .fit ? .fit : .fill }
}

/// The out-of-the-box default. `AsyncImage` keys its fetch on the URL, which is stable data, and each node's slot identity is its `id` — so a reordered list moves images rather than refetching them.
public struct AsyncImageViewProvider: RemoteImageViewProviding {
    public init() {}
    public func makeImageView(url: URL, contentMode: ImageContentMode) -> AnyView {
        AnyView(
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                case .success(let image):
                    image.resizable().aspectRatio(contentMode: contentMode.swiftUI)
                case .failure(let error):
                    Color.clear   /// a broken image URL degrades to nothing, never a crash
                @unknown default:
                    Color.clear
                }
            }
        )
    }
}
