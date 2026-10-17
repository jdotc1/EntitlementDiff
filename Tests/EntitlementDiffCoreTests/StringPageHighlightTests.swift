import XCTest
@testable import EntitlementDiffCore

final class StringPageHighlightTests: XCTestCase {
    func testEscapedUTF16RangePreservesOriginalByteIdentity() throws {
        let prefix = "🙂é e\u{301} "
        let query = "\u{0001}\"\\🙂"
        let raw = prefix + query + " tail"
        let doc = try LeafValueDocument(leaf: XCTUnwrap(InspectorLeaf(.string(raw))))
        let range = prefix.utf8.count..<(prefix.utf8.count + query.utf8.count)
        let page = try XCTUnwrap(doc.stringPage(onPage: 0, matching: range))
        XCTAssertEqual(Array(page.text.utf8), Array(doc.text(onPage: 0).utf8))
        let selected = (page.text as NSString).substring(with: try XCTUnwrap(page.highlight))
        XCTAssertEqual(selected, "\\u{0001}\\\"\\\\🙂")
        XCTAssertFalse(page.continuesBefore); XCTAssertFalse(page.continuesAfter)
        let composed = try XCTUnwrap(doc.stringPage(onPage: 0, matching: 4..<6))
        XCTAssertEqual((composed.text as NSString).substring(with: try XCTUnwrap(composed.highlight)), "é")
        let decomposed = try XCTUnwrap(doc.stringPage(onPage: 0, matching: 7..<10))
        XCTAssertEqual(Array((decomposed.text as NSString).substring(with: try XCTUnwrap(decomposed.highlight)).utf8), Array("e\u{301}".utf8))
    }
    func testCrossPagePortionsAndContinuationAreBounded() throws {
        let raw = String(repeating: "é", count: 511) + "🙂target" + String(repeating: "\u{0001}", count: 1024)
        let doc = try LeafValueDocument(leaf: XCTUnwrap(InspectorLeaf(.string(raw))))
        let match = 1022..<1032
        let first = try XCTUnwrap(doc.stringPage(onPage: 0, matching: match))
        let second = try XCTUnwrap(doc.stringPage(onPage: 1, matching: match))
        XCTAssertTrue(first.continuesAfter); XCTAssertFalse(first.continuesBefore)
        XCTAssertTrue(second.continuesBefore); XCTAssertFalse(second.continuesAfter)
        XCTAssertEqual((first.text as NSString).substring(with: try XCTUnwrap(first.highlight)), "🙂")
        XCTAssertEqual((second.text as NSString).substring(with: try XCTUnwrap(second.highlight)), "target")
        let other = try XCTUnwrap(doc.stringPage(onPage: 2, matching: match))
        XCTAssertNil(other.highlight)
        XCTAssertLessThanOrEqual(other.text.unicodeScalars.count, 4098)
        XCTAssertEqual(Array(other.text.utf8), Array(doc.text(onPage: 2).utf8))
        XCTAssertNil(doc.stringPage(onPage: 0, matching: nil)?.highlight)
    }
}
