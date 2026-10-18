import EntitlementDiffModel
import Foundation
import AppKit
import XCTest
import EntitlementDiffCore
@testable import EntitlementDiffApp

@MainActor final class TreeTextSearchTests: XCTestCase {
    func testTreeScopeExcludesTraversalAndRetainsBothOrder() throws {
        let huge = EntitlementValue.array(Array(repeating: .string("x"), count: 500))
        var current = try EntitlementTreeSearch(previous: huge, current: .string("e\u{301}"), query: "e\u{301}", scope: .current)
        try current.step(); XCTAssertEqual(current.visited, 1)
        try current.step(); XCTAssertTrue(current.complete)
        XCTAssertEqual(current.hits.count, 1); XCTAssertEqual(current.hits.first?.side, .current)
        var previous = try EntitlementTreeSearch(previous: .string("x"), current: huge, query: "x", scope: .previous)
        try previous.step(); try previous.step(); XCTAssertTrue(previous.complete)
        XCTAssertEqual(previous.visited, 1); XCTAssertEqual(previous.hits.count, 1)
        var both = try EntitlementTreeSearch(previous: .string("x"), current: .string("x"), query: "x")
        while !both.complete { try both.step() }
        XCTAssertEqual(both.hits.map(\.side), [.previous, .current])
        var absent = try EntitlementTreeSearch(previous: .string("x"), current: nil, query: "x", scope: .current)
        try absent.step(); XCTAssertTrue(absent.complete); XCTAssertTrue(absent.hits.isEmpty); XCTAssertEqual(absent.visited, 0)
    }
    func testScopeInvalidatesSelectionRetainsQueryAndClearScope() async throws {
        let model = ComparisonModel(reader: TreeUnusedReader()); model.loadExample()
        _ = model.browser.findExactKey("example.feature-labels", revealHidden: true)
        let session = TreeTextSearchSession(change: try XCTUnwrap(model.browser.selectedRow), revision: model.reportRevision)
        session.setQuery(.init(value: "local")); await session.search()?.value
        while session.cursor?.complete == false { await session.advance()?.value }
        session.nextResult(); let old = try XCTUnwrap(session.selectedHit)
        let selection = model.browser.selection, revision = model.reportRevision
        session.setScope(.current)
        XCTAssertNil(session.cursor); XCTAssertNil(session.selectedHitID); XCTAssertEqual(session.input.value, "local")
        let actions = AppActions(model: model); actions.openTreeHit(session, hit: old); XCTAssertNil(actions.focusedValue)
        let clipboard = NSPasteboard.withUniqueName(); defer { clipboard.releaseGlobally() }
        clipboard.setString("sentinel", forType: .string); actions.copyTreeResultDetails(session, to: clipboard)
        XCTAssertEqual(clipboard.string(forType: .string), "sentinel")
        await session.search()?.value
        while session.cursor?.complete == false { await session.advance()?.value }
        session.nextResult(); XCTAssertEqual(session.selectedHit?.side, .current)
        XCTAssertTrue(session.message.contains("Current scope"))
        actions.copyTreeResultDetails(session, to: clipboard)
        XCTAssertTrue(clipboard.string(forType: .string)?.contains("Search scope: Current") == true)
        session.clear(); XCTAssertEqual(session.scope, .current); XCTAssertEqual(session.input.value, "")
        XCTAssertEqual(model.browser.selection, selection); XCTAssertEqual(model.reportRevision, revision)
    }
    func testScopeChangeRejectsLateWorker() async throws {
        let change = EntitlementComparison(previous: .init(["key": .string("x")]), current: .init()).changes[0]
        let session = TreeTextSearchSession(change: change, revision: UUID(), runner: { cursor in
            let work = Task.detached { try await Task.sleep(for: .milliseconds(20)); var next = cursor; try next.step(); return next }
            return try await work.value
        })
        session.setQuery(.init(value: "x")); let work = try XCTUnwrap(session.search())
        session.setScope(.current); let message = session.message
        await work.value
        XCTAssertNil(session.cursor); XCTAssertNil(session.selectedHitID); XCTAssertFalse(session.running)
        XCTAssertEqual(session.scope, .current); XCTAssertEqual(session.input.value, "x"); XCTAssertEqual(session.message, message)
    }
    func testClearTreeCompletedAndPartialPreservesComparisonAndClipboard() async throws {
        let model = ComparisonModel(reader: TreeUnusedReader()); model.loadExample()
        _ = model.browser.findExactKey("example.feature-labels", revealHidden: true)
        let change = try XCTUnwrap(model.browser.selectedRow)
        let revision = model.reportRevision, selection = model.browser.selection
        let session = TreeTextSearchSession(change: change, revision: revision)
        let actions = AppActions(model: model)
        let clipboard = NSPasteboard.withUniqueName(); defer { clipboard.releaseGlobally() }
        clipboard.setString("sentinel", forType: .string)
        XCTAssertFalse(session.canClear)
        session.setQuery(.init(value: "local")); await session.search()?.value
        XCTAssertTrue(session.canClear); XCTAssertFalse(session.cursor?.complete == true)
        session.clear()
        XCTAssertNil(session.cursor); XCTAssertNil(session.selectedHitID)
        XCTAssertEqual(session.input.value, ""); XCTAssertFalse(session.canClear)
        session.setQuery(.init(value: "local")); await session.search()?.value
        while session.cursor?.complete == false { await session.advance()?.value }
        session.nextResult(); let oldHit = try XCTUnwrap(session.selectedHit)
        session.clear(); actions.copyTreeResultDetails(session, to: clipboard)
        actions.openTreeHit(session, hit: oldHit)
        XCTAssertNil(actions.focusedValue); XCTAssertNil(session.selectedHit)
        XCTAssertFalse(session.canSelectNext); XCTAssertFalse(session.canSelectPrevious)
        XCTAssertEqual(clipboard.string(forType: .string), "sentinel")
        XCTAssertEqual(model.browser.selection, selection); XCTAssertEqual(model.reportRevision, revision)
        session.setQuery(.init(value: "research")); await session.search()?.value
        while session.cursor?.complete == false { await session.advance()?.value }
        session.nextResult(); XCTAssertNotNil(session.selectedHit)
        XCTAssertEqual(model.browser.selection, selection)
    }
    func testClearTreeRejectsCancellationInsensitiveLateCompletion() async throws {
        let change = EntitlementComparison(previous: .init(["key": .string("x")]), current: .init()).changes[0]
        let session = TreeTextSearchSession(change: change, revision: UUID(), runner: { cursor in
            let work = Task.detached { try await Task.sleep(for: .milliseconds(20)); var result = cursor; try result.step(); return result }
            return try await work.value
        })
        session.setQuery(.init(value: "x")); let work = try XCTUnwrap(session.search())
        XCTAssertTrue(session.running); XCTAssertTrue(session.canClear)
        session.clear(); let message = session.message
        await work.value
        XCTAssertFalse(session.running); XCTAssertNil(session.cursor); XCTAssertNil(session.selectedHitID)
        XCTAssertEqual(session.input.value, ""); XCTAssertEqual(session.message, message)
        XCTAssertFalse(session.canClear)
    }
    func testSelectedTreeCopyExactPathBytesAndBounds() async throws {
        let nested = try EntitlementDictionary(entries: [.init(key: "e\u{301}\n", value: .array([.string("🙂e\u{301}")]))])
        var cursor = try EntitlementTreeSearch(previous: .dictionary(nested), current: nil, query: "e\u{301}")
        while !cursor.complete { try cursor.step() }
        let hit = try XCTUnwrap(cursor.hits.first)
        let text = try TreeResultDetails.text(key: "é", hit: hit, query: "e\u{301}", complete: true, limited: false)
        XCTAssertTrue(text.contains("Entitlement key: \"\\u{E9}\""))
        XCTAssertTrue(text.contains("dictionary key: \"\\u{65}\\u{301}\\u{A}\""))
        XCTAssertTrue(text.contains("array index (0-based): 0"))
        XCTAssertTrue(text.contains("byte start (1-based): 5"))
        XCTAssertTrue(text.contains("scalar start (1-based): 2"))
        XCTAssertTrue(text.contains("65 CC 81")); XCTAssertTrue(text.contains("status: complete"))
        XCTAssertLessThanOrEqual(text.utf8.count, TreeResultDetails.byteLimit)
        XCTAssertThrowsError(try TreeResultDetails.text(key: String(repeating: "a", count: 20000), hit: hit, query: "e\u{301}", complete: false, limited: true))
    }
    func testSelectedTreeClipboardPreservedOnLimitAndStaleSelection() async throws {
        let model = ComparisonModel(reader: TreeUnusedReader()); model.loadExample()
        _ = model.browser.findExactKey("example.feature-labels", revealHidden: true)
        let session = TreeTextSearchSession(change: try XCTUnwrap(model.browser.selectedRow), revision: model.reportRevision)
        session.setQuery(.init(value: "local")); await session.search()?.value
        while session.cursor?.complete == false { await session.advance()?.value }
        session.nextResult(); let selected = session.selectedHitID
        let board = NSPasteboard.withUniqueName(); defer { board.releaseGlobally() }
        let actions = AppActions(model: model)
        actions.copyTreeResultDetails(session, to: board)
        XCTAssertTrue(try XCTUnwrap(board.string(forType: .string)).contains("6C 6F 63 61 6C"))
        XCTAssertEqual(session.selectedHitID, selected); XCTAssertTrue(session.cursor?.complete == true)
        board.clearContents(); board.setString("sentinel", forType: .string)
        session.setQuery(.init(value: "research")); actions.copyTreeResultDetails(session, to: board)
        XCTAssertEqual(board.string(forType: .string), "sentinel")
        model.loadExample(); actions.copyTreeResultDetails(session, to: board)
        XCTAssertEqual(board.string(forType: .string), "sentinel")
        let longKey = String(repeating: "a", count: 20000)
        // Use an independent formatter boundary for oversized complete paths.
        var cursor = try EntitlementTreeSearch(previous: .dictionary(try EntitlementDictionary(entries: [.init(key: longKey, value: .string("x"))])), current: nil, query: "x")
        while !cursor.complete { try cursor.step() }
        XCTAssertThrowsError(try TreeResultDetails.text(key: "key", hit: XCTUnwrap(cursor.hits.first), query: "x", complete: false, limited: false))
        XCTAssertEqual(board.string(forType: .string), "sentinel")
        let previous = EntitlementSnapshot(sourceName: "Before.app", signingIdentifier: "example", architecture: .arm64,
            entitlements: try EntitlementDictionary(entries: [.init(key: "key", value: .dictionary(try EntitlementDictionary(entries: [.init(key: longKey, value: .string("x"))])))]))
        let current = EntitlementSnapshot(sourceName: "After.app", signingIdentifier: "example", architecture: .arm64, entitlements: .init())
        model.openSavedComparison(try SavedReport.parse(ComparisonReport(previous: previous, current: current).jsonData()))
        _ = model.browser.findExactKey("key", revealHidden: true)
        let oversized = TreeTextSearchSession(change: try XCTUnwrap(model.browser.selectedRow), revision: model.reportRevision)
        oversized.setQuery(.init(value: "x")); await oversized.search()?.value
        while oversized.cursor?.complete == false { await oversized.advance()?.value }
        oversized.nextResult(); actions.copyTreeResultDetails(oversized, to: board)
        XCTAssertEqual(board.string(forType: .string), "sentinel")
        XCTAssertTrue(actions.errorMessage?.contains("64 KiB") == true)
    }
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
