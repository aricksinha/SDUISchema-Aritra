import Foundation

/// A single node in the UI tree.
///
/// `Node` is deliberately dumb and generic — it does NOT grow a
/// field for every component's specific needs. `type` is an open
/// String (new component types are the norm, not the exception);
/// anything type-specific lives in `props` and is decoded by that
/// component's own renderer at render time, not here. This is what
/// lets the schema support an unbounded, ever-growing vocabulary of
/// components without `Node` itself ever changing shape again after
/// v1 ships.
public struct Node: Equatable {
    /// REQUIRED. Missing or wrong-typed → the whole node fails to
    /// decode. A node with no identity can't be tracked, diffed, or
    /// reported on when something goes wrong with it.
    public let id: String

    /// REQUIRED. Open vocabulary — new values are added constantly
    /// as new components ship. An unregistered value is NOT a decode
    /// failure; it's a normal string that the RENDERING layer (not
    /// this package) resolves to a fallback placeholder. Decode-time
    /// and render-time unknown-handling are deliberately different
    /// layers with different concerns.
    public let type: String

    /// OPTIONAL. A reference to design tokens, resolved later by a
    /// `Theme`. Malformed `style` degrades to `nil` — a card missing
    /// its shadow token still functions.
    public let style: StyleRef?

    /// OPTIONAL. Closed-set layout primitives (see `Layout`).
    public let layout: Layout?

    /// Every child is independently resilient — one malformed child
    /// never removes its siblings, and the array itself never
    /// throws. See `ChildSlot`.
    public let children: [ChildSlot]

    /// OPTIONAL. References an entry in the closed, client-defined
    /// `Action` vocabulary (owned by SDUIActions, not this package).
    /// Kept as an opaque String here on purpose — SDUISchema doesn't
    /// need to know what actions exist to model "this node can
    /// trigger one."
    public let actionID: String?

    /// OPTIONAL. A scoped path resolved against this node's (or an
    /// ancestor component instance's) data — e.g. `"$.title"`.
    /// Resolution is the rendering layer's job and must fail closed
    /// on a bad path (render nothing), never crash or leak
    /// unintended data.
    public let dataBinding: String?

    public let accessibility: A11yMeta?
    public let analytics: AnalyticsMeta?

    /// OPTIONAL, opaque. The type-specific payload a component's own
    /// renderer decodes for itself — see the type-level doc comment.
    public let props: JSONValue?

    public init(
        id: String,
        type: String,
        style: StyleRef? = nil,
        layout: Layout? = nil,
        children: [ChildSlot] = [],
        actionID: String? = nil,
        dataBinding: String? = nil,
        accessibility: A11yMeta? = nil,
        analytics: AnalyticsMeta? = nil,
        props: JSONValue? = nil
    ) {
        self.id = id
        self.type = type
        self.style = style
        self.layout = layout
        self.children = children
        self.actionID = actionID
        self.dataBinding = dataBinding
        self.accessibility = accessibility
        self.analytics = analytics
        self.props = props
    }
}

extension Node: Codable {
    private enum CodingKeys: String, CodingKey {
        case id, type, style, layout, children
        case actionID = "actionId"
        case dataBinding, accessibility, analytics, props
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let reporter = decoder.sduiFailureReporter

        // REQUIRED — let these throw. The caller (ChildSlot,
        // ComponentSlot, or Screen for the root) decides what
        // "this node is unusable" means at its level: quarantine a
        // subtree, or — for the root only — propagate all the way up
        // so the app can fall back to a cached screen.
        let id = try container.decode(String.self, forKey: .id)
        let type = try container.decode(String.self, forKey: .type)
        self.id = id
        self.type = type

        // OPTIONAL — each field decoded independently so a malformed
        // `style` can never take `layout`, `props`, or anything else
        // down with it. Degrade to nil and report; never throw.
        self.style = Self.decodeDegrading(StyleRef.self, container, .style, id, type, reporter)
        self.layout = Self.decodeDegrading(Layout.self, container, .layout, id, type, reporter)
        self.accessibility = Self.decodeDegrading(A11yMeta.self, container, .accessibility, id, type, reporter)
        self.analytics = Self.decodeDegrading(AnalyticsMeta.self, container, .analytics, id, type, reporter)
        self.props = Self.decodeDegrading(JSONValue.self, container, .props, id, type, reporter)
        self.actionID = try? container.decodeIfPresent(String.self, forKey: .actionID)
        self.dataBinding = try? container.decodeIfPresent(String.self, forKey: .dataBinding)

        // `children` is non-throwing BY CONSTRUCTION once we're
        // inside the array — `ChildSlot` never rethrows internally.
        // The one remaining failure mode is the `children` VALUE not
        // being an array at all (e.g. sent as a string by mistake).
        // Distinguish "key absent" (the normal, silent case for any
        // leaf node) from "key present but malformed" (a real
        // reportable failure) explicitly — collapsing them into one
        // `try?` would spuriously report a failure on every ordinary
        // leaf node that simply has no children.
        if container.contains(.children) {
            if let children = try? container.decode([ChildSlot].self, forKey: .children) {
                self.children = children
            } else {
                reporter.report(DecodeFailure(nodeID: id, nodeType: type, reason: "children: present but not a valid array"))
                self.children = []
            }
        } else {
            self.children = []
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(type, forKey: .type)
        try container.encodeIfPresent(style, forKey: .style)
        try container.encodeIfPresent(layout, forKey: .layout)
        try container.encode(children, forKey: .children)
        try container.encodeIfPresent(actionID, forKey: .actionID)
        try container.encodeIfPresent(dataBinding, forKey: .dataBinding)
        try container.encodeIfPresent(accessibility, forKey: .accessibility)
        try container.encodeIfPresent(analytics, forKey: .analytics)
        try container.encodeIfPresent(props, forKey: .props)
    }

    /// Decodes one optional field; on ANY failure (wrong type,
    /// malformed nested object) reports it and returns `nil` instead
    /// of throwing. This single helper is what implements the
    /// "quarantine vs. degrade" split at the field level — required
    /// fields (`id`, `type`) skip this and throw for real.
    private static func decodeDegrading<T: Decodable>(
        _ type: T.Type,
        _ container: KeyedDecodingContainer<CodingKeys>,
        _ key: CodingKeys,
        _ nodeID: String,
        _ nodeType: String,
        _ reporter: DecodeFailureReporting
    ) -> T? {
        do {
            return try container.decodeIfPresent(type, forKey: key)
        } catch {
            reporter.report(DecodeFailure(nodeID: nodeID, nodeType: nodeType, reason: "\(key.stringValue): \(error)"))
            return nil
        }
    }
}

/// Wraps a single child so a decode failure on ONE child never
/// throws away the whole `[Node]` array — and therefore never takes
/// down every sibling under a shared parent.
///
/// This is the actual mechanism behind "one bad comma shouldn't
/// blank the whole screen": `JSONDecoder` aborts an array decode on
/// its first element failure, full stop, no partial results. Making
/// the ELEMENT TYPE something that can never throw is the only way
/// around that — there is no array-level flag or decoder option that
/// achieves this.
public enum ChildSlot: Equatable {
    case node(Node)
    case failed(DecodeFailure)

    /// The rendering layer's only real interaction with this type:
    /// a quarantined slot simply isn't rendered.
    public var node: Node? {
        if case .node(let node) = self { return node }
        return nil
    }
}

extension ChildSlot: Codable {
    /// Best-effort keys read ONLY on the failure path, so a broken
    /// child can still report which node/type it was — using
    /// decoding that itself can never throw.
    private enum DiagnosticKeys: String, CodingKey {
        case id, type
    }

    public init(from decoder: Decoder) throws {
        do {
            self = .node(try Node(from: decoder))
        } catch {
            var id: String?
            var type: String?
            if let diagnostics = try? decoder.container(keyedBy: DiagnosticKeys.self) {
                id = try? diagnostics.decodeIfPresent(String.self, forKey: .id)
                type = try? diagnostics.decodeIfPresent(String.self, forKey: .type)
            }
            let failure = DecodeFailure(nodeID: id, nodeType: type, reason: String(describing: error))
            decoder.sduiFailureReporter.report(failure)
            self = .failed(failure)
        }
    }

    public func encode(to encoder: Encoder) throws {
        switch self {
        case .node(let node):
            try node.encode(to: encoder)
        case .failed:
            // A quarantined slot was never valid input — there is
            // nothing faithful to re-encode. An empty object keeps
            // round-tripping well-typed without fabricating data
            // that was never really there.
            var container = encoder.singleValueContainer()
            try container.encode([String: String]())
        }
    }
}
