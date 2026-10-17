import XCTest
@testable import EntitlementDiffCore

final class StringFirstDifferenceTests: XCTestCase {
    func testExactUnicodeAndCrossPagePositions() throws {
        var cursor = StringFirstDifference(previous: String(repeating: "🙂", count: 512) + "é", current: String(repeating: "🙂", count: 512) + "e\u{301}")
        XCTAssertEqual(try cursor.step(), .difference(.init(byteOffset: 2048, scalarOffset: 512, previousByteCount: 2, currentByteCount: 1)))
        let p = try LeafValueDocument(leaf: XCTUnwrap(InspectorLeaf(.string("é"))))
        let page = try XCTUnwrap(p.stringDifferencePage(onPage: 0, byteOffset: 0, scalarByteCount: 2))
        XCTAssertEqual((page.text as NSString).substring(with: try XCTUnwrap(page.highlight)), "é")
    }
    func testPrefixEndEmptyAndEqualAreExplicit() throws {
        var prefix = StringFirstDifference(previous: "🙂", current: "🙂x")
        XCTAssertEqual(try prefix.step(), .difference(.init(byteOffset: 4, scalarOffset: 1, previousByteCount: 0, currentByteCount: 1)))
        var reverse = StringFirstDifference(previous: "x", current: "")
        XCTAssertEqual(try reverse.step(), .difference(.init(byteOffset: 0, scalarOffset: 0, previousByteCount: 1, currentByteCount: 0)))
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
        XCTAssertEqual(try later.step(byteLimit: 8), .difference(.init(byteOffset: 6, scalarOffset: 2, previousByteCount: 1, currentByteCount: 1)))
    }
}
