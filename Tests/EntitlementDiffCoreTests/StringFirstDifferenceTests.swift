import XCTest
@testable import EntitlementDiffCore

final class StringFirstDifferenceTests: XCTestCase {
    func testNextTracksIndependentUTF8OffsetsAndHighlights() throws {
        let a = "a" + String(repeating: "x", count: 511) + "é"
        let b = "🙂" + String(repeating: "x", count: 511) + "\u{200B}"
        var cursor = StringFirstDifference(previous: a, current: b)
        XCTAssertFalse(cursor.movePastDifference())
        guard case .difference = try cursor.step() else { return XCTFail("Missing first") }
        XCTAssertTrue(cursor.movePastDifference())
        guard case .difference(let later) = try cursor.step() else { return XCTFail("Missing later") }
        XCTAssertEqual(later.scalarOffset, 512); XCTAssertEqual(later.previousByteOffset, 512)
        XCTAssertEqual(later.currentByteOffset, 515); XCTAssertEqual(later.pageIndex, 1)
        for (text, offset, length, expected) in [(a, later.previousByteOffset, later.previousByteCount, "é"), (b, later.currentByteOffset, later.currentByteCount, "\u{200B}")] {
            let doc = try LeafValueDocument(leaf: XCTUnwrap(InspectorLeaf(.string(text))))
            let page = try XCTUnwrap(doc.stringDifferencePage(onPage: 1, byteOffset: offset, scalarByteCount: length))
            XCTAssertEqual((page.text as NSString).substring(with: try XCTUnwrap(page.highlight)), expected)
        }
        XCTAssertTrue(cursor.movePastDifference()); XCTAssertEqual(try cursor.step(), .equal)
    }
    func testNextComposedDecomposedAdjacentAndTerminalEOF() throws {
        var cursor = StringFirstDifference(previous: "éZ", current: "e\u{301}Z")
        guard case .difference(let first) = try cursor.step() else { return XCTFail("Missing first") }
        XCTAssertEqual(first.previousScalar?.value, 0xE9); XCTAssertTrue(cursor.movePastDifference())
        guard case .difference(let next) = try cursor.step() else { return XCTFail("Missing adjacent") }
        XCTAssertEqual(next.previousByteOffset, 2); XCTAssertEqual(next.currentByteOffset, 1)
        XCTAssertEqual(next.currentScalar?.value, 0x301); XCTAssertTrue(cursor.movePastDifference())
        guard case .difference(let end) = try cursor.step() else { return XCTFail("Missing EOF") }
        XCTAssertNil(end.previousScalar); XCTAssertEqual(end.previousByteOffset, 3)
        XCTAssertEqual(end.currentByteOffset, 3); XCTAssertTrue(cursor.movePastDifference())
        XCTAssertFalse(cursor.movePastDifference()); XCTAssertEqual(try cursor.step(), .equal)
    }
    func testNextLongEqualIntervalRequiresBoundedContinuation() throws {
        var cursor = StringFirstDifference(previous: "a" + String(repeating: "🙂", count: 5000) + "x", current: "🙂" + String(repeating: "🙂", count: 5000) + "y")
        guard case .difference = try cursor.step() else { return XCTFail("Missing first") }
        XCTAssertTrue(cursor.movePastDifference()); XCTAssertEqual(try cursor.step(byteLimit: Int.max), .more)
        guard case .difference(let later) = try cursor.step() else { return XCTFail("Missing later") }
        XCTAssertEqual(later.scalarOffset, 5001); XCTAssertEqual(later.previousByteOffset, 20001)
        XCTAssertEqual(later.currentByteOffset, 20004)
    }
    func testExactUnicodeAndCrossPagePositions() throws {
        var cursor = StringFirstDifference(previous: String(repeating: "🙂", count: 512) + "é", current: String(repeating: "🙂", count: 512) + "e\u{301}")
        XCTAssertEqual(try cursor.step(), .difference(.init(byteOffset: 2048, scalarOffset: 512, previousScalar: "é", currentScalar: "e")))
        let p = try LeafValueDocument(leaf: XCTUnwrap(InspectorLeaf(.string("é"))))
        let page = try XCTUnwrap(p.stringDifferencePage(onPage: 0, byteOffset: 0, scalarByteCount: 2))
        XCTAssertEqual((page.text as NSString).substring(with: try XCTUnwrap(page.highlight)), "é")
    }
    func testPrefixEndEmptyAndEqualAreExplicit() throws {
        var prefix = StringFirstDifference(previous: "🙂", current: "🙂x")
        XCTAssertEqual(try prefix.step(), .difference(.init(byteOffset: 4, scalarOffset: 1, previousScalar: nil, currentScalar: "x")))
        var reverse = StringFirstDifference(previous: "x", current: "")
        XCTAssertEqual(try reverse.step(), .difference(.init(byteOffset: 0, scalarOffset: 0, previousScalar: "x", currentScalar: nil)))
        var equal = StringFirstDifference(previous: "", current: "")
        XCTAssertEqual(try equal.step(), .equal)
        let doc = try LeafValueDocument(leaf: XCTUnwrap(InspectorLeaf(.string(String(repeating: "é", count: 512)))))
        let end = try XCTUnwrap(doc.stringDifferencePage(onPage: 0, byteOffset: 1024, scalarByteCount: 0))
        XCTAssertEqual((end.text as NSString).substring(with: try XCTUnwrap(end.highlight)), "\"")
        XCTAssertNil(doc.stringDifferencePage(onPage: 0, byteOffset: 1, scalarByteCount: 0)?.highlight)
    }
    func testExplicitBudgetDoesNotClaimEqualityEarly() throws {
        let raw = String(repeating: "🙂", count: 5000)
        var equal = StringFirstDifference(previous: raw, current: raw)
        XCTAssertEqual(try equal.step(byteLimit: Int.max), .more)
        XCTAssertEqual(try equal.step(), .equal)
        var later = StringFirstDifference(previous: "é🙂\"", current: "é🙂\\")
        XCTAssertEqual(try later.step(byteLimit: 8), .more)
        XCTAssertEqual(try later.step(byteLimit: 8), .more)
        XCTAssertEqual(try later.step(byteLimit: 8), .difference(.init(byteOffset: 6, scalarOffset: 2, previousScalar: "\"", currentScalar: "\\")))
    }
}
