import XCTest
import EntitlementDiffCore
@testable import EntitlementDiffModel

final class InspectorProjectionSessionTests: XCTestCase {
    private func change(_ values: [EntitlementValue], key: String = "key") -> EntitlementChange {
        EntitlementComparison(previous: .init(), current: .init([key: .array(values)])).rows[0]
    }

    func testChangesOnlyOmitsTwoAbsentValues() {
        let projection = ValueInspector(previous: nil, current: nil, expanded: ["root"], changesOnly: true)
        XCTAssertTrue(projection.rows.isEmpty)
        XCTAssertEqual(projection.matchingRowCount, 0)
    }

    func testReadsAndUnchangedControlsReuseProjection() {
        var session = InspectorProjectionSession(change: change([.integer(1)]), comparisonRevision: UUID())
        let revision = session.projectionRevision
        _ = session.projection.rows.map(\.kind)
        _ = session.projection.rows.map(\.kind)
        session.setQuery(""); session.setChangesOnly(false)
        session.previousPage(); session.nextPage()
        XCTAssertEqual(session.projectionRevision, revision)
        XCTAssertEqual(session.projection.rows.last?.current, .integer(1))
    }

    func testControlsRebuildOnlyForRelevantChangesAndPreserveBounds() {
        var session = InspectorProjectionSession(change: change((0..<120).map { .integer(Int64($0)) }), comparisonRevision: UUID())
        let first = session.projectionRevision
        XCTAssertEqual(session.projection.rows.count, 50)
        session.nextPage()
        XCTAssertNotEqual(session.projectionRevision, first)
        XCTAssertEqual(session.projection.pageOffset, 50)
        XCTAssertEqual(session.projection.rows.first?.id, "root/i49")
        session.setQuery("[119]")
        XCTAssertEqual(session.projection.pageOffset, 0)
        XCTAssertEqual(session.projection.rows.last?.current, .integer(119))
        session.setChangesOnly(true)
        XCTAssertEqual(session.projection.rows.last?.kind, .added)
        session.setQuery(String(repeating: "x", count: 300))
        XCTAssertEqual(session.query.unicodeScalars.count, 256)
        let bounded = session.projectionRevision
        session.setQuery(String(repeating: "x", count: 301))
        XCTAssertEqual(session.projectionRevision, bounded)
        session.collapse()
        XCTAssertEqual(session.projection.rows.map(\.id), ["root"])
        session.toggleExpansion("root")
        XCTAssertEqual(session.projection.rows.count, 50)
    }

    func testSameKeyReplacementCapturesNewValuesAndResetsNavigation() throws {
        let oldChange = change([.integer(Int64.max), .boolean(true)])
        var old = InspectorProjectionSession(change: oldChange, comparisonRevision: UUID())
        old.setQuery("[1]"); old.setChangesOnly(true)
        let newChange = change([.string("9223372036854775807"), .integer(1)])
        let fresh = InspectorProjectionSession(change: newChange, comparisonRevision: UUID())
        XCTAssertEqual(old.selectionID, fresh.selectionID)
        XCTAssertNotEqual(old.comparisonRevision, fresh.comparisonRevision)
        XCTAssertEqual(fresh.query, ""); XCTAssertFalse(fresh.changesOnly)
        XCTAssertEqual(fresh.expanded, ["root"])
        XCTAssertEqual(fresh.projection.rows[1].current, .string("9223372036854775807"))
        XCTAssertEqual(fresh.projection.rows[2].current, .integer(1))
        XCTAssertEqual(old.projection.rows.last?.current, .boolean(true))
        // Presentation operations never replace or truncate the captured entitlement.
        let originalJSON = try newChange.selectedJSON()
        var edited = fresh
        edited.setQuery("missing"); edited.collapse()
        XCTAssertEqual(try newChange.selectedJSON(), originalJSON)
    }

    func testLimitedSearchRemainsExplicitAndByteDistinctKeysRemainDistinct() throws {
        let value = EntitlementValue.array(Array(repeating: .integer(1), count: 3_000))
        let row = EntitlementComparison(previous: .init(), current: .init(["large": value])).rows[0]
        var session = InspectorProjectionSession(change: row, comparisonRevision: UUID())
        session.setQuery("[2999]")
        XCTAssertTrue(session.projection.searchIncomplete)
        XCTAssertTrue(session.projection.rows.isEmpty)
        let keys = try EntitlementDictionary(entries: [.init(key: "é", value: .boolean(true)), .init(key: "e\u{301}", value: .integer(1))])
        let rows = EntitlementComparison(previous: .init(), current: keys).rows
        let a = InspectorProjectionSession(change: rows[0], comparisonRevision: UUID())
        let b = InspectorProjectionSession(change: rows[1], comparisonRevision: a.comparisonRevision)
        XCTAssertNotEqual(a.selectionID, b.selectionID)
        XCTAssertNotEqual(a.projection.rows[0].current, b.projection.rows[0].current)
    }
}
