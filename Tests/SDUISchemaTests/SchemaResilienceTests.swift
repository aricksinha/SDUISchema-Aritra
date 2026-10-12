import XCTest
@testable import SDUISchema

/// Records every reported failure so tests can assert on WHAT was
/// reported, not just that decoding didn't crash. Real host apps
/// wire a reporter that forwards to their analytics SDK; this one
/// exists purely to make the resilience contract testable.
final class RecordingReporter: DecodeFailureReporting {
    private(set) var failures: [DecodeFailure] = []
    func report(_ failure: DecodeFailure) { failures.append(failure) }
}

final class SchemaResilienceTests: XCTestCase {

    private func decodeFixture(_ name: String, reporter: RecordingReporter) throws -> Screen {
        let url = Bundle.module.url(forResource: name, withExtension: "json", subdirectory: "Fixtures")!
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.userInfo[.decodeFailureReporter] = reporter
        return try decoder.decode(Screen.self, from: data)
    }

    // MARK: - The headline guarantee

    func test_oneMalformedChild_neverShrinksOrThrowsTheSiblingArray() throws {
        let reporter = RecordingReporter()
        let screen = try decodeFixture("valid_screen_with_partial_failures", reporter: reporter)

        XCTAssertEqual(
            screen.root.children.count, 3,
            "the array must retain a slot for every child that was present in the JSON, healthy or not"
        )
    }

    // MARK: - Class 2a: a required field missing → quarantine

    func test_childMissingRequiredID_isQuarantinedNotSilentlyDropped() throws {
        let reporter = RecordingReporter()
        let screen = try decodeFixture("valid_screen_with_partial_failures", reporter: reporter)

        guard case .failed(let failure) = screen.root.children[2] else {
            return XCTFail("third child is missing `id` and must decode as .failed, not .node")
        }
        XCTAssertFalse(failure.reason.isEmpty)
        XCTAssertTrue(
            reporter.failures.contains(failure),
            "every quarantined node must produce exactly one reported failure — silent quarantine defeats the point"
        )
    }

    func test_componentTemplateMissingRequiredID_isQuarantinedIndependently() throws {
        let reporter = RecordingReporter()
        let screen = try decodeFixture("valid_screen_with_partial_failures", reporter: reporter)

        XCTAssertNil(
            screen.resolvedComponent("brokenTemplate"),
            "a broken template resolves to nil, never crashes lookup"
        )
        XCTAssertNotNil(
            screen.resolvedComponent("productCard"),
            "a broken SIBLING template must not affect an unrelated, valid template"
        )
    }

    // MARK: - Class 2b: an optional field malformed → degrade, keep the node

    func test_childWithMalformedStyle_stillDecodesWithStyleNilButRestIntact() throws {
        let reporter = RecordingReporter()
        let screen = try decodeFixture("valid_screen_with_partial_failures", reporter: reporter)

        guard case .node(let degraded) = screen.root.children[1] else {
            return XCTFail("a malformed OPTIONAL field must degrade the field, not quarantine the whole node")
        }
        XCTAssertNil(degraded.style, "malformed style must resolve to nil, never crash the node")
        XCTAssertEqual(
            degraded.props?["content"]?.stringValue,
            "Still renders, just without style",
            "fields unrelated to the malformed one must decode normally"
        )
        XCTAssertTrue(reporter.failures.contains { $0.nodeID == "degraded-style-node" })
    }

    // MARK: - The healthy-path control

    func test_wellFormedChild_decodesWithNoReportedFailures() throws {
        let reporter = RecordingReporter()
        let screen = try decodeFixture("valid_screen_with_partial_failures", reporter: reporter)

        guard case .node(let title) = screen.root.children[0] else {
            return XCTFail("a fully well-formed node must never end up quarantined")
        }
        XCTAssertEqual(title.props?["content"]?.stringValue, "Welcome back")
        XCTAssertFalse(reporter.failures.contains { $0.nodeID == "title" })
    }

    // MARK: - The one deliberate exception: the root

    func test_unparseableRootNode_propagatesAsAThrow() {
        let malformedRoot = Data("""
        { "screenId": "broken", "structureVersion": 1, "components": {}, "root": { "type": "stack" } }
        """.utf8) // root object is missing its required `id`

        XCTAssertThrowsError(
            try JSONDecoder().decode(Screen.self, from: malformedRoot),
            "an unparseable ROOT has no partial UI to save — this must throw so the caller falls back to a cached screen or an error state, per the resilience design"
        )
    }

    // MARK: - Vocabulary is open: an unknown node `type` is not a decode failure at all

    func test_unknownNodeType_decodesSuccessfully_asAPlainString() throws {
        let json = Data("""
        { "id": "x1", "type": "x-experimentalCarousel" }
        """.utf8)
        let node = try JSONDecoder().decode(Node.self, from: json)
        XCTAssertEqual(node.type, "x-experimentalCarousel", "an unrecognized type is a normal string at decode time — resolving it to a fallback view is the RENDERING layer's job, not this package's")
    }
}
