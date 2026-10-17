import XCTest
@testable import EntitlementDiffCore

final class StringValueSearchTests: XCTestCase {
    func testCrossPageUTF8OffsetsAndOverlappingMatches() throws {
        var search = try StringValueSearch(source: String(repeating: "é", count: 511) + "🙂target target", query: "🙂target")
        XCTAssertEqual(try search.step(), .match(.init(byteOffset: 1022, scalarOffset: 511)))
        var overlapping = try StringValueSearch(source: "aaaa", query: "aa")
        for i in 0...2 { XCTAssertEqual(try overlapping.step(byteLimit: 2), .match(.init(byteOffset: i, scalarOffset: i))) }
        XCTAssertEqual(try overlapping.step(), .end)
        XCTAssertEqual(try overlapping.step(), .end)
    }
    func testBudgetContinuationKeepsBoundaryMatchAndExactUnicode() throws {
        var search = try StringValueSearch(source: String(repeating: "x", count: 32767) + "éEND", query: "éEND")
        XCTAssertEqual(try search.step(byteLimit: Int.max), .more)
        XCTAssertEqual(try search.step(), .match(.init(byteOffset: 32767, scalarOffset: 32767)))
        var unicode = try StringValueSearch(source: "é e\u{301} É", query: "e\u{301}")
        XCTAssertEqual(try unicode.step(), .match(.init(byteOffset: 3, scalarOffset: 2)))
        XCTAssertEqual(try unicode.step(), .end)
        var whitespace = try StringValueSearch(source: " x ", query: " x ")
        XCTAssertEqual(try whitespace.step(), .match(.init(byteOffset: 0, scalarOffset: 0)))
    }
    func testQueryBoundsEmptySourceAndScalarPageMapping() throws {
        XCTAssertThrowsError(try StringValueSearch(source: "a", query: ""))
        XCTAssertThrowsError(try StringValueSearch(source: "a", query: String(repeating: "é", count: 513)))
        var empty = try StringValueSearch(source: "", query: "x")
        XCTAssertEqual(try empty.step(), .end)
        var atPage = try StringValueSearch(source: String(repeating: "🙂", count: 512) + "match", query: "match")
        guard case .match(let match) = try atPage.step() else { return XCTFail("No match") }
        XCTAssertEqual(match.byteOffset, 2048)
        XCTAssertEqual(match.pageIndex, 1)
        var maximum = try StringValueSearch(source: String(repeating: "é", count: 512), query: String(repeating: "é", count: 512))
        guard case .match = try maximum.step() else { return XCTFail("Maximum query not matched") }
    }
}
