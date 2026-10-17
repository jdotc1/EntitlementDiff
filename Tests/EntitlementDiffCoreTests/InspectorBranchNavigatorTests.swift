import Foundation
import XCTest
@testable import EntitlementDiffCore

final class InspectorBranchNavigatorTests: XCTestCase {
    func testExplicitArrayJumpReachesBeyondSearchPrefixAndKeepsExactLeaf() throws {
        let values = (0..<2_100).map { EntitlementValue.integer(Int64($0)) }
        var navigation = InspectorBranchNavigator(previous: .array(values), current: .array(values + [.unsignedInteger(UInt64.max)]))
        XCTAssertEqual(navigation.rows.count, 50)
        XCTAssertTrue(navigation.goToArrayIndex(2_099))
        XCTAssertEqual(navigation.rows.map(\.label), ["[2099]", "[2100]"])
        XCTAssertEqual(navigation.rows.last?.previous, nil)
        XCTAssertEqual(navigation.rows.last?.current, .unsignedInteger(UInt64.max))
        let copied = try XCTUnwrap(InspectorLeaf(navigation.rows.last?.current)).jsonData()
        XCTAssertTrue(String(decoding: copied, as: UTF8.self).contains("18446744073709551615"))
        XCTAssertFalse(navigation.hasNext)
        XCTAssertFalse(navigation.goToArrayIndex(Int.max))
        XCTAssertFalse(navigation.goToArrayIndex(-1))
        XCTAssertEqual(navigation.offset, 2_099)
        navigation.previousPage()
        XCTAssertEqual(navigation.offset, 2_049)
        navigation.firstPage()
        XCTAssertEqual(navigation.rows.first?.id, "root/i0")
        navigation.nextPage()
        XCTAssertEqual(navigation.rows.first?.id, "root/i50")
    }

    func testDictionaryContinuationMergesLaterKeysWithoutLossOrUnicodeCollapse() throws {
        let entries = (0..<2_010).map { EntitlementEntry(key: String(format: "k%04d", $0), value: .integer(Int64($0))) }
        let previous = try EntitlementDictionary(entries: entries + [.init(key: "é", value: .boolean(false))])
        let current = try EntitlementDictionary(entries: Array(entries.dropFirst()) + [.init(key: "e\u{301}", value: .boolean(true))])
        var navigation = InspectorBranchNavigator(previous: .dictionary(previous), current: .dictionary(current))
        var rows: [InspectorRow] = []
        repeat {
            XCTAssertLessThanOrEqual(navigation.rows.count, 50)
            rows += navigation.rows
            if !navigation.hasNext { break }
            navigation.nextPage()
        } while true
        XCTAssertEqual(rows.count, 2_012)
        XCTAssertEqual(Set(rows.map(\.id)).count, rows.count)
        XCTAssertEqual(rows.first?.label, "\"e\u{301}\"")
        XCTAssertNil(rows.first?.previous)
        XCTAssertEqual(rows.last?.label, "\"é\"")
        XCTAssertNil(rows.last?.current)
        XCTAssertEqual(rows[2_010].current, .integer(2_009))
        let finalIDs = navigation.rows.map(\.id)
        navigation.previousPage(); navigation.nextPage()
        XCTAssertEqual(navigation.rows.map(\.id), finalIDs)
        XCTAssertFalse(navigation.goToArrayIndex(0))
    }

    func testDepthBeyondTwelveAndBackRestoreParentCursor() {
        var value = EntitlementValue.string("deep leaf")
        for _ in 0..<20 { value = .array([value]) }
        var navigation = InspectorBranchNavigator(previous: nil, current: .array(Array(repeating: .integer(0), count: 55) + [value]))
        navigation.nextPage()
        let selected = navigation.rows[5]
        XCTAssertTrue(navigation.enter(selected.id))
        for _ in 0..<19 { XCTAssertTrue(navigation.enter(navigation.rows[0].id)) }
        XCTAssertEqual(navigation.depth, 20)
        XCTAssertEqual(navigation.rows[0].current, .string("deep leaf"))
        XCTAssertFalse(navigation.enter(navigation.rows[0].id))
        for _ in 0..<20 { navigation.back() }
        XCTAssertEqual(navigation.offset, 50)
        XCTAssertEqual(navigation.rows[5].id, selected.id)
        XCTAssertFalse(navigation.canGoBack)
    }

    func testMixedContainersEmptyValuesAndImmutableCapture() throws {
        let old = EntitlementValue.dictionary(.init(["x": .string("")]))
        let new = EntitlementValue.array([.data(Data())])
        var navigation = InspectorBranchNavigator(previous: old, current: new)
        XCTAssertEqual(navigation.rows.map(\.label), ["Previous structure", "Current structure"])
        XCTAssertTrue(navigation.enter("root/previous"))
        XCTAssertEqual(navigation.rows[0].previous, .string(""))
        XCTAssertNil(navigation.rows[0].current)
        navigation.back()
        XCTAssertTrue(navigation.enter("root/current"))
        XCTAssertNil(navigation.rows[0].previous)
        XCTAssertEqual(navigation.rows[0].current, .data(Data()))
        navigation.back()
        XCTAssertEqual(navigation.root.previous, old)
        XCTAssertEqual(navigation.root.current, new)
        let empty = InspectorBranchNavigator(previous: .array([]), current: nil)
        XCTAssertTrue(empty.rows.isEmpty)
        XCTAssertFalse(empty.hasNext)
        XCTAssertEqual(empty.arrayCount, 0)
    }
}
