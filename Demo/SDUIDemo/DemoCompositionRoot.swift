import SDUIDesignSystem
import SDUIRendering

enum DemoComponentType: String, CaseIterable {
    case text
    case stack

    func register(in registry: inout RendererRegistry) {
        switch self {
        case .text:
            registry.register(TextNodeRenderer(), for: rawValue)
        case .stack:
            registry.register(StackNodeRenderer(), for: rawValue)
        }
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

    static func makeRegistry() -> RendererRegistry {
        var registry = RendererRegistry()
        for component in DemoComponentType.allCases {
            component.register(in: &registry)
        }
        return registry
    }
}
