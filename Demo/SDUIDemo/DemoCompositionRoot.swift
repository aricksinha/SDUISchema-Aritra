import SDUIDesignSystem
import SDUIRendering

/// The only place in the demo that knows which renderers exist.
/// Adding a renderer later is one `register` line here, plus a sample
/// in `SampleCatalog`.
enum DemoCompositionRoot {
    static func makeTheme() -> StaticTheme {
        .placeholder
    }

    static func makeRegistry() -> RendererRegistry {
        var registry = RendererRegistry()
        registry.register(TextNodeRenderer(), for: "text")
        return registry
    }
}
