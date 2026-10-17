import Foundation
import XCTest
@testable import EntitlementDiffCore

final class CoreTests: XCTestCase {
    func testBooleanIntegerAndStringRemainDistinct() throws {
        let dictionary = try FoundationEntitlementDecoder().decode([
            "boolean": NSNumber(value: true), "integer": NSNumber(value: 1), "string": "1"
        ])
        XCTAssertEqual(dictionary["boolean"], .boolean(true))
        XCTAssertEqual(dictionary["integer"], .integer(1))
        XCTAssertEqual(dictionary["string"], .string("1"))
        XCTAssertNotEqual(dictionary["boolean"], dictionary["integer"])
    }

    func testUnsignedMaximumIsNotTruncated() throws {
        let dictionary = try FoundationEntitlementDecoder().decode(["large": NSNumber(value: UInt64.max)])
        XCTAssertEqual(dictionary["large"], .unsignedInteger(UInt64.max))
    }

    func testFiniteRealDataAndDateArePreserved() throws {
        let date = Date(timeIntervalSinceReferenceDate: 123.125)
        let dictionary = try FoundationEntitlementDecoder().decode([
            "real": NSNumber(value: 1.25), "data": Data([0, 255]), "date": date
        ])
        XCTAssertEqual(dictionary["real"], .real(1.25))
        XCTAssertEqual(dictionary["data"], .data(Data([0, 255])))
        XCTAssertEqual(dictionary["date"], .date(date))
    }

    func testInvalidRootsAndUnsupportedTypesFail() {
        XCTAssertThrowsError(try FoundationEntitlementDecoder().decode([true, false]))
        XCTAssertThrowsError(try FoundationEntitlementDecoder().decode(["null": NSNull()]))
        XCTAssertThrowsError(try FoundationEntitlementDecoder().decode(NSDictionary(object: "v", forKey: NSNumber(value: 2))))
    }

    func testNonFiniteNumbersFail() {
        for number in [Double.nan, Double.infinity, -Double.infinity] {
            XCTAssertThrowsError(try FoundationEntitlementDecoder().decode(["x": NSNumber(value: number)]))
        }
    }

    func testNodeByteAndDepthBudgets() {
        XCTAssertThrowsError(try FoundationEntitlementDecoder(limits: .init(maxDepth: 1)).decode(["a": ["b": ["c": true]]]))
        XCTAssertThrowsError(try FoundationEntitlementDecoder(limits: .init(maxNodes: 2)).decode(["a": [1, 2, 3]]))
        XCTAssertThrowsError(try FoundationEntitlementDecoder(limits: .init(maxBytes: 4)).decode(["a": "12345"]))
        XCTAssertThrowsError(try FoundationEntitlementDecoder(limits: .init(maxDepth: 0)).decode([:]))
    }

    func testNestedDictionaryOrderDoesNotMatter() {
        let a = EntitlementDictionary(["z": .integer(2), "a": .dictionary(.init(["y": .boolean(true), "x": .string("v")]))])
        let b = EntitlementDictionary(["a": .dictionary(.init(["x": .string("v"), "y": .boolean(true)])), "z": .integer(2)])
        XCTAssertEqual(a, b)
        XCTAssertTrue(EntitlementComparison(previous: a, current: b).changes.isEmpty)
    }

    func testArrayOrderAndMultiplicityMatter() {
        XCTAssertNotEqual(EntitlementValue.array([.string("a"), .string("b")]), .array([.string("b"), .string("a")]))
        XCTAssertNotEqual(EntitlementValue.array([.integer(1)]), .array([.integer(1), .integer(1)]))
    }

    func testAbsentFalseAndChangedTypes() {
        let a = EntitlementDictionary(["removed": .boolean(false), "changed": .integer(1), "same": .string("yes")])
        let b = EntitlementDictionary(["added": .boolean(false), "changed": .boolean(true), "same": .string("yes")])
        let diff = EntitlementComparison(previous: a, current: b)
        XCTAssertEqual(diff.rows.map(\.key), ["added", "changed", "removed", "same"])
        XCTAssertEqual(diff.rows.map(\.kind), [.added, .changed, .removed, .unchanged])
        XCTAssertNil(diff.rows[0].previous)
        XCTAssertEqual(diff.rows[0].current, .boolean(false))
        XCTAssertEqual(diff.changes.count, 3)
    }

    func testUnicodeStringsUseByteIdentity() {
        let composed = "\u{00E9}"
        let decomposed = "e\u{0301}"
        XCTAssertEqual(composed, decomposed) // Swift String intentionally differs from our contract.
        XCTAssertNotEqual(EntitlementValue.string(composed), .string(decomposed))
    }

    func testUnicodeKeysDoNotCollapse() throws {
        let dictionary = try EntitlementDictionary(entries: [
            .init(key: "\u{00E9}", value: .boolean(true)),
            .init(key: "e\u{0301}", value: .boolean(false))
        ])
        XCTAssertEqual(dictionary.entries.count, 2)
        XCTAssertEqual(dictionary["\u{00E9}"], .boolean(true))
        XCTAssertEqual(dictionary["e\u{0301}"], .boolean(false))
        XCTAssertEqual(Set(EntitlementComparison(previous: .init(), current: dictionary).rows.map(\.id)).count, 2)
    }

    func testDuplicateExactKeysAreRejected() {
        XCTAssertThrowsError(try EntitlementDictionary(entries: [.init(key: "a", value: .integer(1)), .init(key: "a", value: .integer(2))]))
    }

    func testNegativeZeroIsVisibleAsAChange() {
        XCTAssertNotEqual(EntitlementValue.real(-0.0), .real(0.0))
        XCTAssertNotEqual(EntitlementValue.real(1), .integer(1))
    }

    func testJSONIsDeterministicAndPreservesLargeIntegers() throws {
        let a = snapshot("Before.app", .init(["z": .boolean(false), "large": .unsignedInteger(UInt64.max)]))
        let b = snapshot("After.app", .init(["z": .boolean(true), "large": .unsignedInteger(UInt64.max)]))
        let report = try ComparisonReport(previous: a, current: b)
        let first = try report.jsonData()
        for _ in 0..<10 { XCTAssertEqual(first, try report.jsonData()) }
        let root = try XCTUnwrap(JSONSerialization.jsonObject(with: first) as? [String: Any])
        XCTAssertEqual(root["schemaVersion"] as? Int, 1)
        let json = try XCTUnwrap(String(data: first, encoding: .utf8))
        XCTAssertTrue(json.contains("\"18446744073709551615\""))
        XCTAssertTrue(json.contains("notPerformed"))
        XCTAssertFalse(json.contains("generatedAt"))
        XCTAssertFalse(json.contains("/Users/"))
    }

    func testReportRejectsArchitectureMismatchOrMissingIdentity() {
        let previous = snapshot("a.app", .init())
        let current = EntitlementSnapshot(sourceName: "b.app", signingIdentifier: "test", architecture: .x86_64, entitlements: .init())
        XCTAssertThrowsError(try ComparisonReport(previous: previous, current: current))
        let missingIdentity = EntitlementSnapshot(sourceName: "b.app", signingIdentifier: "", architecture: .arm64, entitlements: .init())
        XCTAssertThrowsError(try ComparisonReport(previous: previous, current: missingIdentity))
    }

    func testReportKeepsInspectionBoundaryAndDirections() throws {
        let report = try ComparisonReport(previous: snapshot("a.app", .init()), current: snapshot("b.app", .init(["key": .boolean(false)])))
        let text = report.text()
        XCTAssertTrue(text.contains("Signature validity: not checked"))
        XCTAssertTrue(text.contains("ADDED"))
        XCTAssertTrue(text.contains("Previous: <absent>"))
        XCTAssertTrue(text.contains("Current: false"))
        XCTAssertTrue(text.contains("main executable"))
    }

    func testControlAndBidirectionalTextIsEscaped() {
        XCTAssertEqual(DisplayText.escaped("x\n\u{202E}y\t"), "x\\u{000A}\\u{202E}y\\u{0009}")
        XCTAssertEqual(DisplayText.quoted("a\"b\\c"), "\"a\\\"b\\\\c\"")
    }

    func testReportEmitsOnlyChangesButBothCompleteSnapshots() throws {
        let report = try ComparisonReport(previous: snapshot("a", .init(["same": .boolean(true)])), current: snapshot("b", .init(["same": .boolean(true), "new": .integer(3)])))
        let root = try XCTUnwrap(JSONSerialization.jsonObject(with: report.jsonData()) as? [String: Any])
        XCTAssertEqual((root["changes"] as? [Any])?.count, 1)
        let current = try XCTUnwrap(root["current"] as? [String: Any])
        XCTAssertEqual((current["entitlements"] as? [Any])?.count, 2)
    }

    func testSharedComparisonKeepsSchemaOneExampleBytes() throws {
        let pair = ExampleSnapshots.pair(architecture: .arm64)
        let report = try ComparisonReport(previous: pair.previous, current: pair.current)
        XCTAssertEqual(report.comparison.rows.count, 6)
        XCTAssertEqual(report.changes.count, 5)
        let examples = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("Examples")
        XCTAssertEqual(try report.jsonData(), try Data(contentsOf: examples.appendingPathComponent("example-report.json")))
        XCTAssertEqual(report.text(), try String(contentsOf: examples.appendingPathComponent("example-report.txt"), encoding: .utf8))
    }

    private func snapshot(_ name: String, _ entries: EntitlementDictionary) -> EntitlementSnapshot {
        .init(sourceName: name, signingIdentifier: "test.app", architecture: .arm64, entitlements: entries)
    }
}
