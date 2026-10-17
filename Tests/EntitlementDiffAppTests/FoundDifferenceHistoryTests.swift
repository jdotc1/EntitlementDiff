import Foundation
import XCTest
import EntitlementDiffCore
@testable import EntitlementDiffApp

@MainActor
final class FoundDifferenceHistoryTests: XCTestCase {
    func testFixedHistoryEvictionAndReplayKeepOrdinals() {
        var history = FoundDifferenceHistory<Int>()
        for n in 0..<70 { XCTAssertEqual(history.append(n).ordinal, n + 1) }
        XCTAssertEqual(history.entries.count, 64); XCTAssertEqual(history.entries.first?.ordinal, 7)
        XCTAssertNotNil(history.notice); XCTAssertNil(history.next())
        for expected in stride(from: 69, through: 7, by: -1) { XCTAssertEqual(history.previous()?.ordinal, expected) }
        XCTAssertFalse(history.canPrevious); XCTAssertNil(history.previous())
        for expected in 8...70 { XCTAssertEqual(history.next()?.ordinal, expected) }
        XCTAssertTrue(history.isAtFrontier)
        history = .init(); XCTAssertNil(history.notice); XCTAssertNil(history.previous())
    }
    func testDataReplayDoesNotRunComparisonAndResumesFrontier() async throws {
        let counter = HistoryRunCounter()
        let model = FocusedDataDifference(previous: Data([0, 1, 2]), current: Data([9, 8, 7, 0]), runner: { cursor in
            await counter.increment(); var next = cursor; let result = try next.step(); return (next, result)
        })
        try await XCTUnwrap(model.find()).value; try await XCTUnwrap(model.next()).value
        model.previousFound(); XCTAssertEqual(model.differenceCount, 1)
        XCTAssertEqual(model.currentContext?.markedHex, "[09]")
        try await XCTUnwrap(model.next()).value
        let replayRuns = await counter.count; XCTAssertEqual(replayRuns, 2)
        try await XCTUnwrap(model.next()).value
        XCTAssertEqual(model.position?.byteOffset, 2); XCTAssertEqual(model.differenceCount, 3)
        try await XCTUnwrap(model.next()).value; try await XCTUnwrap(model.next()).value
        XCTAssertEqual(model.phase, .finished); model.previousFound()
        XCTAssertEqual(model.position?.byteOffset, 2)
        try await XCTUnwrap(model.next()).value
        XCTAssertEqual(model.phase, .finished); XCTAssertEqual(model.previousContext?.markedHex, "[EOF]")
        let finalRuns = await counter.count; XCTAssertEqual(finalRuns, 5)
    }
    func testStringReplayPreservesIndependentUTF8DetailsAndFinishedState() async throws {
        let model = FocusedStringDifference(previous: "aé", current: "🙂\u{200B}x")
        try await XCTUnwrap(model.find()).value; try await XCTUnwrap(model.next()).value
        let saved = try XCTUnwrap(model.position)
        model.previousFound(); XCTAssertEqual(model.position?.currentByteOffset, 0)
        try await XCTUnwrap(model.next()).value; XCTAssertEqual(model.position, saved)
        XCTAssertEqual(model.position?.previousByteOffset, 1); XCTAssertEqual(model.position?.currentByteOffset, 4)
        XCTAssertEqual(model.position?.currentDetail.utf8Bytes, "E2 80 8B")
        try await XCTUnwrap(model.next()).value; try await XCTUnwrap(model.next()).value
        XCTAssertEqual(model.phase, .finished); model.previousFound()
        XCTAssertEqual(model.position, saved); XCTAssertEqual(model.phase, .different)
        try await XCTUnwrap(model.next()).value; XCTAssertEqual(model.phase, .finished)
        try await XCTUnwrap(model.find()).value
        XCTAssertFalse(model.canPrevious); XCTAssertNil(model.historyNotice); XCTAssertEqual(model.differenceCount, 1)
    }
    func testBothSessionsBoundHistoryAndContinueAfterReplay() async throws {
        let data = FocusedDataDifference(previous: Data(repeating: 0, count: 72), current: Data(repeating: 1, count: 72))
        let text = FocusedStringDifference(previous: String(repeating: "a", count: 72), current: String(repeating: "🙂", count: 72))
        try await XCTUnwrap(data.find()).value; try await XCTUnwrap(text.find()).value
        for _ in 1..<70 { try await XCTUnwrap(data.next()).value; try await XCTUnwrap(text.next()).value }
        for _ in 0..<63 { data.previousFound(); text.previousFound() }
        XCTAssertEqual(data.differenceCount, 7); XCTAssertEqual(text.differenceCount, 7)
        XCTAssertFalse(data.canPrevious); XCTAssertFalse(text.canPrevious)
        XCTAssertTrue(data.historyNotice?.contains("difference 7") == true)
        XCTAssertTrue(text.historyNotice?.contains("difference 7") == true)
        for _ in 0..<64 { try await XCTUnwrap(data.next()).value; try await XCTUnwrap(text.next()).value }
        XCTAssertEqual(data.differenceCount, 71); XCTAssertEqual(text.differenceCount, 71)
        XCTAssertEqual(text.position?.currentByteOffset, 280)
        data.cancel(); text.cancel(); XCTAssertNil(data.position); XCTAssertNil(text.position)
        XCTAssertNil(data.historyNotice); XCTAssertNil(text.historyNotice)
    }
    func testPendingDataResultCannotPopulateRestartedHistory() async throws {
        let gate = HistoryPublicationGate()
        let model = FocusedDataDifference(previous: Data([0, 1]), current: Data([9, 8]), runner: { cursor in
            var next = cursor; let result = try next.step(); await gate.waitOnSecond(); return (next, result)
        })
        try await XCTUnwrap(model.find()).value; let pending = try XCTUnwrap(model.next())
        while !(await gate.entered) { await Task.yield() }
        XCTAssertFalse(model.canPrevious); model.previousFound()
        try await XCTUnwrap(model.find()).value; await gate.release(); await pending.value
        XCTAssertEqual(model.differenceCount, 1); XCTAssertFalse(model.canPrevious)
        XCTAssertEqual(model.position?.byteOffset, 0)
    }
    func testPendingStringResultCannotPopulateRestartedHistory() async throws {
        let gate = HistoryPublicationGate()
        let model = FocusedStringDifference(previous: "aé", current: "🙂x", runner: { cursor in
            var next = cursor; let result = try next.step(); await gate.waitOnSecond(); return (next, result)
        })
        try await XCTUnwrap(model.find()).value; let pending = try XCTUnwrap(model.next())
        while !(await gate.entered) { await Task.yield() }
        XCTAssertFalse(model.canPrevious); model.previousFound()
        try await XCTUnwrap(model.find()).value; await gate.release(); await pending.value
        XCTAssertEqual(model.differenceCount, 1); XCTAssertFalse(model.canPrevious)
        XCTAssertEqual(model.position?.currentByteOffset, 0)
    }
}
private actor HistoryRunCounter {
    var count = 0
    func increment() { count += 1 }
}
private actor HistoryPublicationGate {
    var entered = false
    private var calls = 0
    private var waiter: CheckedContinuation<Void, Never>?
    func waitOnSecond() async {
        calls += 1
        if calls == 2 { entered = true; await withCheckedContinuation { waiter = $0 } }
    }
    func release() { waiter?.resume(); waiter = nil }
}
