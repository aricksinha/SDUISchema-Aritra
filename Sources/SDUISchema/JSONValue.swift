import Foundation

/// A minimal, dependency-free representation of "any JSON value."
///
/// This exists so `Node` never needs a field for every component's
/// specific needs. `Node.props` is a `JSONValue?`; each component's
/// own renderer decodes ITS OWN strongly-typed `Props` struct from
/// that opaque payload at render time. Adding the 50th component
/// type never touches `Node` — only the new renderer, which is the
/// whole point of an SDK meant to scale past what its authors
/// personally anticipated.
public enum JSONValue: Equatable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case object([String: JSONValue])
    case array([JSONValue])
    case null
}

extension JSONValue: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self = .null
            return
        }

        // Order matters here, and it's a genuine Codable gotcha worth
        // calling out explicitly: on some JSON backing stores, a JSON
        // `true`/`false` and a JSON `1`/`0` are not always cleanly
        // distinguishable once bridged through NSNumber. Trying Bool
        // BEFORE Double avoids the classic bug where `true` silently
        // decodes as `1.0` instead of `true`.
        if let bool = try? container.decode(Bool.self) {
            self = .bool(bool)
        } else if let number = try? container.decode(Double.self) {
            self = .number(number)
        } else if let string = try? container.decode(String.self) {
            self = .string(string)
        } else if let array = try? container.decode([JSONValue].self) {
            self = .array(array)
        } else if let object = try? container.decode([String: JSONValue].self) {
            self = .object(object)
        } else {
            // A leaf that matched none of the above shouldn't be
            // possible for well-formed JSON, but `props` is opaque
            // and untrusted-shaped by design — degrade instead of
            // throwing, same philosophy as everywhere else in this
            // package.
            self = .null
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value): try container.encode(value)
        case .number(let value): try container.encode(value)
        case .bool(let value): try container.encode(value)
        case .object(let value): try container.encode(value)
        case .array(let value): try container.encode(value)
        case .null: try container.encodeNil()
        }
    }
}

// Convenience accessors so component renderers don't have to
// pattern-match on the enum for every single field read.
public extension JSONValue {
    subscript(key: String) -> JSONValue? {
        guard case .object(let dictionary) = self else { return nil }
        return dictionary[key]
    }

    subscript(index: Int) -> JSONValue? {
        guard case .array(let values) = self, values.indices.contains(index) else { return nil }
        return values[index]
    }

    var stringValue: String? {
        if case .string(let value) = self { return value }
        return nil
    }

    var numberValue: Double? {
        if case .number(let value) = self { return value }
        return nil
    }

    var boolValue: Bool? {
        if case .bool(let value) = self { return value }
        return nil
    }

    var arrayValue: [JSONValue]? {
        if case .array(let value) = self { return value }
        return nil
    }
}
