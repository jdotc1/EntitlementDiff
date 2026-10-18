import EntitlementDiffModel
import Foundation
import XCTest
import EntitlementDiffCore
@testable import EntitlementDiffApp

@MainActor final class TreeTextSearchTests: XCTestCase {
    func testResultNavigationRetainsSelectionAcrossContinuationAndStopsAtEnds() async throws {
        let change = EntitlementComparison(previous: .init(["key": .array(Array(repeating: .string("x"), count: 80))]), current: .init()).changes[0]
        let session = TreeTextSearchSession(change: change, revision: UUID())
        session.setQuery(.init(value: "x")); await session.search()?.value
        XCTAssertNil(session.selectedHit); XCTAssertFalse(session.canSelectPrevious)
        while (session.cursor?.hits.count ?? 0) < 2 { await session.advance()?.value }
        session.nextResult(); let first = try XCTUnwrap(session.selectedHit)
        XCTAssertEqual(session.selectedIndex, 0)
        session.previousResult(); XCTAssertEqual(session.selectedHitID, first.id)
        session.nextResult(); let second = try XCTUnwrap(session.selectedHit)
        XCTAssertEqual(session.selectedIndex, 1)
        await session.advance()?.value
        XCTAssertEqual(session.selectedHitID, second.id)
        while session.cursor?.complete == false { await session.advance()?.value }
        for _ in 0..<100 { session.nextResult() }
        XCTAssertEqual(session.selectedIndex, 79); XCTAssertFalse(session.canSelectNext)
        XCTAssertEqual(session.positionLabel, "Result 80 of 80 found.")
        session.selectHit(first.id); XCTAssertEqual(session.selectedIndex, 0)
        session.selectHit(UUID()); XCTAssertEqual(session.selectedHitID, first.id)
        session.setQuery(.init(value: "y"))
        XCTAssertNil(session.selectedHitID); XCTAssertNil(session.selectedHit)
        XCTAssertFalse(session.canSelectNext); XCTAssertFalse(session.canSelectPrevious)
        await session.search()?.value; XCTAssertNil(session.selectedHitID)
    }
    func testNavigationCannotSelectDuringWorkOrRestoreAfterQueryChange() async throws {
        let change = EntitlementComparison(previous: .init(["key": .array(Array(repeating: .string("x"), count: 80))]), current: .init()).changes[0]
        let session = TreeTextSearchSession(change: change, revision: UUID())
        session.setQuery(.init(value: "x")); await session.search()?.value
        session.nextResult(); let selected = session.selectedHitID
        let work = session.advance()
        session.nextResult(); session.previousResult(); session.selectHit(UUID())
        XCTAssertEqual(session.selectedHitID, selected)
        session.setQuery(.init(value: "z")); await work?.value
        XCTAssertNil(session.selectedHitID); XCTAssertNil(session.cursor)
    }
    func testContinuationExactKeysSidesAndLongString() throws {
        let dictionary = try EntitlementDictionary(entries: [.init(key: "é", value: .string("needle")), .init(key: "e\u{301}", value: .string("needle"))])
        var search = try EntitlementTreeSearch(previous: .array(Array(repeating: .integer(1), count: 100) + [.dictionary(dictionary)]), current: .string(String(repeating: "x", count: 40000) + "🙂needle"), query: "needle")
        try search.step(); XCTAssertFalse(search.complete); XCTAssertTrue(search.hits.isEmpty)
        var steps = 1
        while !search.complete && !search.limited && steps < 100 { try search.step(); steps += 1 }
        XCTAssertTrue(search.complete); XCTAssertEqual(search.hits.count, 3)
        XCTAssertNotEqual(search.hits[0].path, search.hits[1].path)
        XCTAssertEqual(search.hits[0].side, .previous); XCTAssertEqual(search.hits[2].side, .current)
        XCTAssertEqual(search.hits[2].match.byteOffset, 40004); XCTAssertEqual(search.hits[2].match.scalarOffset, 40001)
    }
    func testCapsFirstOccurrenceAndInvalidQuery() throws {
        XCTAssertThrowsError(try EntitlementTreeSearch(previous: nil, current: nil, query: ""))
        var search = try EntitlementTreeSearch(previous: .array(Array(repeating: .string("xx"), count: 205)), current: nil, query: "x")
        for _ in 0..<500 { if search.limited { break }; try search.step() }
        XCTAssertTrue(search.limited); XCTAssertFalse(search.complete); XCTAssertEqual(search.hits.count, 200)
        XCTAssertTrue(search.hits.allSatisfy { $0.match.byteOffset == 0 })
    }
    func testResultOpenChecksCurrentSelectionRevisionAndReset() async throws {
        let model = ComparisonModel(reader: TreeUnusedReader())
        model.loadExample(); _ = model.browser.findExactKey("example.feature-labels", revealHidden: true)
        let change = try XCTUnwrap(model.browser.selectedRow)
        let session = TreeTextSearchSession(change: change, revision: model.reportRevision)
        session.setQuery(.init(value: "local")); try await XCTUnwrap(session.search()).value
        for _ in 0..<12 {
            if session.cursor?.complete == true { break }
            if let work = session.advance() { await work.value }
        }
        let hit = try XCTUnwrap(session.cursor?.hits.first)
        let actions = AppActions(model: model)
        actions.openTreeHit(session, hit: hit)
        XCTAssertEqual(actions.focusedValue?.initialScalar, hit.match.scalarOffset + 1)
        XCTAssertEqual(actions.focusedValue?.initialMatchRange, hit.match.byteOffset..<(hit.match.byteOffset + hit.queryByteCount))
        actions.focusedValue = nil
        model.loadExample(); actions.openTreeHit(session, hit: hit); XCTAssertNil(actions.focusedValue)
        session.setQuery(.init(value: "other")); XCTAssertNil(session.cursor)
        actions.openTreeHit(session, hit: hit); XCTAssertNil(actions.focusedValue)
    }
    func testQueryChangeRejectsLateWork() async throws {
        let change = EntitlementComparison(previous: .init(["key": .string("x")]), current: .init()).changes[0]
        let session = TreeTextSearchSession(change: change, revision: UUID(), runner: { cursor in
            let task = Task.detached { try await Task.sleep(for: .milliseconds(20)); var next = cursor; try next.step(); return next }
            return try await task.value
        })
        session.setQuery(.init(value: "x")); let work = try XCTUnwrap(session.search())
        session.setQuery(.init(value: "y")); await work.value
        XCTAssertNil(session.cursor); XCTAssertFalse(session.running); XCTAssertEqual(session.input.value, "y")
    }
}

private struct TreeUnusedReader: SnapshotReading {
    func read(at url: URL, architecture: Architecture) async throws -> EntitlementSnapshot { throw CancellationError() }
}
