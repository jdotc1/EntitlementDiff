import Foundation
import XCTest
@testable import EntitlementDiffCore

final class InspectorNavigationTests: XCTestCase {
    func testSearchFindsCollapsedDescendantsAndRetainsAncestors() {
        let value = EntitlementValue.dictionary(.init([
            "options": .dictionary(.init(["needle": .integer(42), "other": .boolean(true)])),
            "unrelated": .string("needle is a value, not a path")
        ]))
        let tree = ValueInspector(previous: nil, current: value, expanded: [], query: "needle")
        XCTAssertEqual(tree.rows.map(\.depth), [0, 1, 2])
        XCTAssertEqual(tree.rows.last?.current, .integer(42))
        XCTAssertTrue(tree.rows.last?.displayPath.contains("options") == true)
        XCTAssertFalse(tree.searchIncomplete)
        XCTAssertTrue(ValueInspector(previous: nil, current: value, expanded: [], query: "missing").rows.isEmpty)
    }

    func testChangesOnlyAndPaginationPreserveTypedIdentity() {
        let old = EntitlementValue.array((0..<150).map { .integer(Int64($0)) })
        let new = EntitlementValue.array((0..<150).map { $0 == 75 ? .boolean(true) : .integer(Int64($0)) })
        let filtered = ValueInspector(previous: old, current: new, expanded: ["root"], changesOnly: true)
        XCTAssertEqual(filtered.rows.map(\.id), ["root", "root/i75"])
        XCTAssertEqual(filtered.rows.last?.previous, .integer(75))
        XCTAssertEqual(filtered.rows.last?.current, .boolean(true))
        let first = ValueInspector(previous: old, current: new, expanded: ["root"], maxRows: 50)
        let next = ValueInspector(previous: old, current: new, expanded: ["root"], maxRows: 50, offset: 50)
        XCTAssertEqual(first.rows.count, 50)
        XCTAssertTrue(first.hasNextPage)
        XCTAssertEqual(next.pageOffset, 50)
        XCTAssertEqual(next.rows.first?.id, "root/i49")
        XCTAssertTrue(Set(first.rows.map(\.id)).isDisjoint(with: next.rows.map(\.id)))
        let clamped = ValueInspector(previous: old, current: new, expanded: ["root"], maxRows: 50, offset: Int.max)
        XCTAssertEqual(clamped.pageOffset, 150)
        XCTAssertFalse(clamped.hasNextPage)
    }

    func testSearchScanLimitIsExplicitAndCopyIsUnaffected() throws {
        let value = EntitlementValue.array(Array(repeating: .integer(1), count: 3_000))
        let limited = ValueInspector(previous: nil, current: value, expanded: [], query: "[2999]")
        XCTAssertTrue(limited.searchIncomplete)
        XCTAssertTrue(limited.rows.isEmpty)
        let full = ValueInspector(previous: nil, current: value, expanded: ["root"], maxRows: 50, offset: 1950)
        XCTAssertEqual(full.rows.count, 50)
        XCTAssertFalse(full.hasNextPage)
        XCTAssertTrue(full.searchIncomplete)
        let change = EntitlementComparison(previous: .init(), current: .init(["large": value])).rows[0]
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: change.selectedJSON()) as? [String: Any])
        let current = try XCTUnwrap(json["current"] as? [String: Any])
        XCTAssertEqual((current["value"] as? [Any])?.count, 3_000)
    }
}
