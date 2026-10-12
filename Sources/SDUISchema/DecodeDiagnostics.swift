import Foundation

/// Describes why a piece of the tree couldn't be fully decoded.
///
/// This is a VALUE that flows through the model, never a thrown
/// error that escapes it. A `DecodeFailure` is what a quarantined
/// `ChildSlot`/`ComponentSlot` carries instead of a `Node` — the
/// failure is data, not an exception, which is precisely what lets
/// a broken node sit quietly next to working siblings instead of
/// taking the whole array down with it.

public struct DecodeFailure: Equatable, Codable {
    public let nodeID: String?
    public let nodeType: String?
    public let reason: String
    public let schemaVersion: Int?

    public init(nodeID: String?, nodeType: String?, reason: String, schemaVersion: Int? = nil) {
        self.nodeID = nodeID
        self.nodeType = nodeType
        self.reason = reason
        self.schemaVersion = schemaVersion
    }
}

/// Injected at the Composition Root so a decode-time failure reaches
/// real telemetry (Firebase, Datadog, whatever the app already uses)
/// without `SDUISchema` knowing an analytics SDK exists. A rising
/// rate of reports here is a backend signal — a bad deploy or a
/// serializer bug — not client noise; alert on it accordingly.
public protocol DecodeFailureReporting {
    func report(_ failure: DecodeFailure)
}

/// The default until the host app wires a real one. Silence is never
/// the intended END state — but `SDUISchema` itself must not assume
/// any particular analytics stack, so the safe default is "do
/// nothing" until the Composition Root says otherwise.
public struct NoOpDecodeFailureReporter: DecodeFailureReporting {
    public init() {}
    public func report(_ failure: DecodeFailure) {}
}

/// A narrow, deliberate exception to "no ambient global state."
///
/// `Decodable.init(from:)` gives you no way to inject a dependency —
/// `JSONDecoder.decode` calls it directly, there is no seam to pass
/// a reporter through. Swift's `userInfo` dictionary on
/// `JSONDecoder`/`Decoder` is the "correct" DI mechanism for this
/// exact problem and is what `Node`/`ChildSlot`/`ComponentSlot`
/// actually read from — `DecodeDiagnostics.reporter` exists ONLY as
/// the fallback when a caller decodes via a plain
/// `JSONDecoder()` without setting `userInfo`, so tests and quick
/// call sites don't silently lose every failure report. Nothing else
/// in this SDK relies on global mutable state — this is scoped to
/// the one place Codable's design leaves no alternative.
public enum DecodeDiagnostics {
    public static var reporter: DecodeFailureReporting = NoOpDecodeFailureReporter()
}

public extension CodingUserInfoKey {
    static let decodeFailureReporter = CodingUserInfoKey(rawValue: "com.sdui.decodeFailureReporter")!
}

extension Decoder {
    /// Prefer the reporter set on `userInfo` (real DI) and fall back
    /// to the ambient default only if the caller didn't configure one.
    var sduiFailureReporter: DecodeFailureReporting {
        (userInfo[.decodeFailureReporter] as? DecodeFailureReporting) ?? DecodeDiagnostics.reporter
    }
}
