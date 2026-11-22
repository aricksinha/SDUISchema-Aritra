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

    func register(
        in registry: inout RendererRegistry,
        onButtonAction: @escaping (String) -> Void
    ) {
        switch self {
        case .text:
            registry.register(TextNodeRenderer(), for: rawValue)
        case .stack:
            registry.register(StackNodeRenderer(), for: rawValue)
        case .image:
            let imageProvider = AsyncImageViewProvider()
            registry.register(ImageNodeRenderer(provider: imageProvider), for: rawValue)
        case .button:
            registry.register(DemoButtonNodeRenderer(onAction: onButtonAction), for: rawValue)
        }
    }
}

/// The demo handles button actions locally so it can show feedback without app-specific behavior in the SDK.
private struct DemoButtonNodeRenderer: NodeRenderer {
    let onAction: (String) -> Void

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

/// The only place in the demo that knows which renderers exist.
/// Add new component types to `DemoComponentType`; its exhaustive
/// renderer registration and `DemoPropertiesEditor` require rendering
/// and properties editing to be set up together. Add a sample in
/// `SampleCatalog` as well.
enum DemoCompositionRoot {
    static func makeTheme() -> StaticTheme {
        .placeholder
    }

    static func makeRegistry(onButtonAction: @escaping (String) -> Void = { _ in }) -> RendererRegistry {
        var registry = RendererRegistry()
        for component in DemoComponentType.allCases {
            component.register(in: &registry, onButtonAction: onButtonAction)
        }
        return registry
    }
}
