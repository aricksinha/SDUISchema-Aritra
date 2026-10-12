import Foundation

/// Carried as plain data on every `Node` so the rendering layer's
/// accessibility DECORATOR (not the node renderers themselves) can
/// attach `.accessibilityLabel()`, `.accessibilityHidden()`, etc.
/// Keeping this as data — rather than the renderer reaching into an
/// accessibility API directly — is what lets accessibility behavior
/// evolve without touching every component renderer.
public struct A11yMeta: Codable, Equatable {
    public let label: String?
    public let hint: String?
    public let isHeader: Bool?
    public let hidden: Bool?

    public init(label: String? = nil, hint: String? = nil, isHeader: Bool? = nil, hidden: Bool? = nil) {
        self.label = label
        self.hint = hint
        self.isHeader = isHeader
        self.hidden = hidden
    }
}

/// Same reasoning as `A11yMeta`: analytics is metadata a decorator
/// reads and acts on, never something a component renderer calls out
/// to directly.
public struct AnalyticsMeta: Codable, Equatable {
    public let eventName: String?
    public let properties: [String: JSONValue]?

    public init(eventName: String? = nil, properties: [String: JSONValue]? = nil) {
        self.eventName = eventName
        self.properties = properties
    }
}
