import Foundation
import XCTest
@testable import EntitlementDiffCore

final class ValueInspectorTests: XCTestCase {
    func testExactKeysTypesAndPositionalArrays() throws {
        let a = try EntitlementDictionary(entries: [.init(key: "é", value: .boolean(true)), .init(key: "e\u{301}", value: .integer(1))])
        let tree = ValueInspector(previous: .dictionary(a), current: .dictionary(a), expanded: ["root"])
        XCTAssertEqual(tree.rows.count, 3)
        XCTAssertNotEqual(tree.rows[1].id, tree.rows[2].id)
        let array = ValueInspector(previous: .array([.boolean(true), .integer(1)]), current: .array([.integer(1)]), expanded: ["root"])
        XCTAssertEqual(array.rows.map(\.kind), [.changed, .changed, .removed])
        XCTAssertEqual(array.rows[1].label, "[0]")
        XCTAssertEqual(InspectorRow.summary(nil), "Absent")
        XCTAssertEqual(InspectorRow.summary(.array([])), "Array (0 items)")
    }
    func testRowDepthAndScalarBudgets() {
        let wide = EntitlementValue.array(Array(repeating: .string(String(repeating: "x", count: 500)), count: 1_000))
        let tree = ValueInspector(previous: nil, current: wide, expanded: ["root"], maxRows: 5)
        XCTAssertEqual(tree.rows.count, 5)
        XCTAssertTrue(tree.limited)
        XCTAssertLessThan(InspectorRow.summary(tree.rows[1].current).unicodeScalars.count, 280)
        let deep = ValueInspector(previous: nil, current: .array([.array([.integer(1)])]), expanded: ["root", "root/i0"], maxDepth: 1)
        XCTAssertEqual(deep.rows.count, 2)
        XCTAssertTrue(deep.limited)
        XCTAssertFalse(deep.rows[1].expandable)
        XCTAssertEqual(ValueInspector(previous: nil, current: wide, expanded: []).rows.count, 1)
    }
    func testNestedChangesAndCompleteTaggedCopy() throws {
        let old = EntitlementDictionary(["removed": .string("old"), "nested": .array([.boolean(true)])])
        let new = EntitlementDictionary(["added": .unsignedInteger(UInt64.max), "nested": .array([.integer(1)])])
        let nestedID = "root/k" + Data("nested".utf8).base64EncodedString()
        let tree = ValueInspector(previous: .dictionary(old), current: .dictionary(new), expanded: ["root", nestedID])
        XCTAssertEqual(tree.rows.map(\.kind), [.changed, .added, .changed, .changed, .removed])
        let row = EntitlementComparison(previous: .init(["key": .dictionary(old)]), current: .init(["key": .dictionary(new)])).rows[0]
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: row.selectedJSON()) as? [String: Any])
        XCTAssertEqual(json["key"] as? String, "key")
        let text = String(decoding: try row.selectedJSON(), as: UTF8.self)
        XCTAssertTrue(text.contains(String(UInt64.max)))
        XCTAssertTrue(text.contains("boolean"))
        XCTAssertTrue(text.contains("integer"))
        XCTAssertTrue(text.contains("removed"))
    }
}
