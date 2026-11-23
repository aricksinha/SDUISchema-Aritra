import Foundation
import SwiftUI
import SDUISchema
import SDUIDesignSystem
import SDUIRendering

enum DemoButtonAction: String, CaseIterable, Identifiable {
    case checkout
    case addToCart
    case showMessage

    var id: String { rawValue }

    var title: String {
        switch self {
        case .checkout: return "Checkout"
        case .addToCart: return "Add to cart"
        case .showMessage: return "Show a message"
        }
    }
}

enum DemoComponentType: String, CaseIterable {
    case text
    case stack
    case image
    case button
    case card

    func register(
        in registry: inout RendererRegistry,
        showsDiagnostics: Bool,
        onButtonAction: @escaping (String) -> Void
    ) {
        switch self {
        case .text:
            registry.register(TextNodeRenderer(), for: rawValue)
        case .stack:
            registry.register(StackNodeRenderer(), for: rawValue)
        case .image:
            registry.register(DemoImageNodeRenderer(showsDiagnostics: showsDiagnostics), for: rawValue)
        case .button:
            registry.register(DemoButtonNodeRenderer(onAction: onButtonAction), for: rawValue)
        case .card:
            registry.register(DemoCardNodeRenderer(onAction: onButtonAction), for: rawValue)
        }
    }
}

private struct DemoImageNodeRenderer: NodeRenderer {
    let showsDiagnostics: Bool

    func makeView(for node: Node, context: RenderContext) -> AnyView {
        guard let rawURL = node.props?["url"]?.stringValue,
              let url = URL(string: rawURL),
              let scheme = url.scheme?.lowercased(),
              (scheme == "http" || scheme == "https"),
              url.host != nil else {
            return AnyView(EmptyView())
        }

        let contentMode: ContentMode = node.props?["contentMode"]?.stringValue == "fill" ? .fill : .fit
        let nodeID = node.id
        return AnyView(
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                case .success(let image):
                    image.resizable().aspectRatio(contentMode: contentMode)
                case .failure(let error):
                    imageFailure(nodeID: nodeID, url: rawURL, error: error)
                @unknown default:
                    imageFailure(
                        nodeID: nodeID,
                        url: rawURL,
                        error: URLError(.unknown)
                    )
                }
            }
        )
    }

    private func imageFailure(nodeID: String, url: String, error: Error) -> some View {
        Group {
            if showsDiagnostics {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Image failed to load", systemImage: "exclamationmark.triangle")
                        .font(.caption.weight(.semibold))
                    Text("Node ID: \(nodeID)")
                    Text("JSON field: props.url")
                    Text("URL: \(url)")
                    Text("Cause: \(error.localizedDescription)")
                    Text("Resolution: verify the URL is reachable, returns image data, and is allowed by the app's network security settings.")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
            } else {
                Label("Image unavailable", systemImage: "photo")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(10)
                    .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
            }
        }
    }
}

/// The demo handles button actions locally so it can show feedback without app-specific behavior in the SDK.
private struct DemoButtonNodeRenderer: NodeRenderer {
    let onAction: (String) -> Void

    var appliesNodeTapAction: Bool { false }

    func makeView(for node: Node, context: RenderContext) -> AnyView {
        let label = makeLabel(for: node, context: context)
        guard let actionID = node.actionID else { return label }
        return AnyView(
            Button {
                onAction(actionID)
            } label: {
                label
            }
        )
    }

    private func makeLabel(for node: Node, context: RenderContext) -> AnyView {
        let title = node.props?["title"]?.stringValue
        let systemImage = node.props?["systemImage"]?.stringValue

        if let title, let systemImage {
            return AnyView(
                HStack(spacing: 8) {
                    Image(systemName: systemImage)
                    Text(title)
                }
            )
        }
        if let title {
            return AnyView(Text(title))
        }
        if let systemImage {
            return AnyView(Image(systemName: systemImage))
        }

        let children = context.childViews(of: node)
        guard !children.isEmpty else { return AnyView(EmptyView()) }
        return AnyView(HStack(spacing: 8) { ForEach(children) { $0.view } })
    }
}

private struct DemoCardNodeRenderer: NodeRenderer {
    let onAction: (String) -> Void

    var appliesNodeTapAction: Bool { false }

    func makeView(for node: Node, context: RenderContext) -> AnyView {
        let content = StackNodeRenderer()
            .makeView(for: node, context: context)
            .frame(maxWidth: .infinity, alignment: .leading)
        guard let actionID = node.actionID else { return AnyView(content) }

        return AnyView(
            Button {
                onAction(actionID)
            } label: {
                content
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        )
    }
}

/// The only place in the demo that knows which renderers exist.
/// Add new component types to `DemoComponentType`; its exhaustive
/// renderer registration and `DemoPropertiesEditor` require rendering
/// and properties editing to be set up together. Add a sample in
/// `SampleCatalog` as well.
enum DemoCompositionRoot {
    static func makeTheme() -> StaticTheme {
        .placeholder
    }

    static func makeRegistry(
        showsDiagnostics: Bool = UnknownNodePlaceholder.defaultShowsDiagnostics,
        onButtonAction: @escaping (String) -> Void = { _ in }
    ) -> RendererRegistry {
        var registry = RendererRegistry(
            fallback: UnknownNodePlaceholder(showsDiagnostics: showsDiagnostics)
        )
        for component in DemoComponentType.allCases {
            component.register(
                in: &registry,
                showsDiagnostics: showsDiagnostics,
                onButtonAction: onButtonAction
            )
        }
        return registry
    }
}
