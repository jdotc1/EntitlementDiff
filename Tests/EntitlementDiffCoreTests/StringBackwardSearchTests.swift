import XCTest
@testable import EntitlementDiffCore

final class StringBackwardSearchTests: XCTestCase {
    func testReverseOverlapDirectionChangesAndEndpoints() throws {
        var cursor = try StringValueSearch(source: "aaaa", query: "aa")
        for i in 0...2 { XCTAssertEqual(try cursor.step(), .match(.init(byteOffset: i, scalarOffset: i))) }
        cursor = try cursor.searching(.backward)
        XCTAssertEqual(try cursor.step(), .match(.init(byteOffset: 1, scalarOffset: 1)))
        XCTAssertEqual(try cursor.step(), .match(.init(byteOffset: 0, scalarOffset: 0)))
        XCTAssertEqual(try cursor.step(), .end)
        cursor = try cursor.searching(.forward)
        XCTAssertEqual(try cursor.step(), .match(.init(byteOffset: 1, scalarOffset: 1)))
        cursor = try cursor.searching(.backward)
        XCTAssertEqual(try cursor.step(), .match(.init(byteOffset: 0, scalarOffset: 0)))
    }
    func testReverseBudgetAndSplitUnicodePreserveOriginalOffsets() throws {
        let prefix = String(repeating: "é", count: 511)
        let raw = prefix + "🙂e\u{301}" + String(repeating: "x", count: 32769) + "🙂e\u{301}"
        var cursor = try StringValueSearch(source: raw, query: "🙂e\u{301}")
        var found: [StringValueSearch.Match] = []
        while found.count < 2 {
            if case .match(let match) = try cursor.step() { found.append(match) }
        }
        cursor = try cursor.searching(.backward)
        XCTAssertEqual(try cursor.step(byteLimit: Int.max), .more)
        var result = try cursor.step(byteLimit: 2)
        while result == .more { result = try cursor.step(byteLimit: 2) }
        XCTAssertEqual(result, .match(.init(byteOffset: 1022, scalarOffset: 511)))
        XCTAssertEqual(found[0].pageIndex, 0)
        cursor = try cursor.searching(.forward)
        var forward = try cursor.step()
        while forward == .more { forward = try cursor.step() }
        XCTAssertEqual(forward, .match(found[1]))
    }
    func testReverseUsesExactUnicodeAndNeverStartsWithoutMatch() throws {
        var cursor = try StringValueSearch(source: "é e\u{301} é e\u{301}", query: "e\u{301}")
        XCTAssertThrowsError(try cursor.searching(.backward))
        XCTAssertEqual(try cursor.step(), .match(.init(byteOffset: 3, scalarOffset: 2)))
        XCTAssertEqual(try cursor.step(), .match(.init(byteOffset: 10, scalarOffset: 7)))
        cursor = try cursor.searching(.backward)
        XCTAssertEqual(try cursor.step(), .match(.init(byteOffset: 3, scalarOffset: 2)))
        XCTAssertEqual(try cursor.step(), .end)
    }
}
