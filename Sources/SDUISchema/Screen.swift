import Foundation

/// Same non-throwing philosophy as `ChildSlot`, applied to component
/// TEMPLATES rather than tree children. One malformed template in
/// the `components` table must not take down every card on the
/// screen that happens to reference a completely different, valid
/// template.
public enum ComponentSlot: Equatable {
    case node(Node)
    case failed(DecodeFailure)

    public var node: Node? {
        if case .node(let node) = self { return node }
        return nil
    }
}

extension ComponentSlot: Codable {
    public init(from decoder: Decoder) throws {
        do {
            self = .node(try Node(from: decoder))
        } catch {
            let failure = DecodeFailure(nodeID: nil, nodeType: nil, reason: String(describing: error))
            decoder.sduiFailureReporter.report(failure)
            self = .failed(failure)
        }
    }

    public func encode(to encoder: Encoder) throws {
        switch self {
        case .node(let node): try node.encode(to: encoder)
        case .failed:
            var container = encoder.singleValueContainer()
            try container.encode([String: String]())
        }
    }
}

/// A single screen payload from the server.
///
/// `structureVersion` gates whether THIS client's parser can even
/// attempt to read the shape at all. Bump it ONLY for a genuine
/// breaking change to Node/Screen's structure (e.g. `children`
/// changing from an array to something else). A new node `type`, a
/// new design token, or a new `Action` case are vocabulary — an
/// OPEN, ever-growing set — and must never require a version bump.
/// Conflating the two is the most common versioning mistake: it
/// turns "a designer added a color" into a forced client update.
public struct Screen: Equatable {
    public let screenID: String
    public let structureVersion: Int
    public let components: [String: ComponentSlot]
    public let root: Node

    public init(screenID: String, structureVersion: Int, components: [String: ComponentSlot] = [:], root: Node) {
        self.screenID = screenID
        self.structureVersion = structureVersion
        self.components = components
        self.root = root
    }
}

extension Screen: Codable {
    private enum CodingKeys: String, CodingKey {
        case screenID = "screenId", structureVersion, components, root
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        screenID = try container.decode(String.self, forKey: .screenID)
        structureVersion = try container.decode(Int.self, forKey: .structureVersion)

        if container.contains(.components) {
            components = (try? container.decode([String: ComponentSlot].self, forKey: .components)) ?? [:]
        } else {
            components = [:]
        }

        // The ONE place a throw is deliberately allowed to propagate
        // all the way up. If the entry point of the whole screen is
        // unparseable, there is no partial UI worth saving — the
        // caller (the networking/state layer, not this package)
        // should catch this and fall back to a cached last-good
        // screen or an explicit error state, per the resilience
        // write-up. Swallowing it here would hide a genuinely
        // unrecoverable payload behind a confusingly blank screen.
        root = try container.decode(Node.self, forKey: .root)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(screenID, forKey: .screenID)
        try container.encode(structureVersion, forKey: .structureVersion)
        try container.encode(components, forKey: .components)
        try container.encode(root, forKey: .root)
    }
}

public extension Screen {
    /// Resolves a `componentID` reference (as found in a node's
    /// `props`, e.g. `{"componentId": "productCard", "data": {...}}`)
    /// against this screen's template table. Returns `nil` — never
    /// throws — for an unknown ID or a template that itself failed
    /// to decode. The rendering layer treats both cases identically:
    /// render nothing for that subtree, report it, move on.
    ///
    /// Deliberately NOT a dedicated `ComponentRef` type at the
    /// schema level — "reference a template by id with instance
    /// data" is exactly the kind of type-specific shape that belongs
    /// in a node's opaque `props`, per the same reasoning that keeps
    /// `Node` generic in the first place.
    func resolvedComponent(_ componentID: String) -> Node? {
        components[componentID]?.node
    }
}
