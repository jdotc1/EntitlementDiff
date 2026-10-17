import Foundation
import XCTest
import EntitlementDiffCore
@testable import EntitlementDiffApp

@MainActor
final class FocusedDataDifferenceTests: XCTestCase {
    func testExplicitContinuationRevealRestartAndEquality() async throws {
        let a = Data(repeating: 0, count: 16385)
        var b = a; b.append(0x80)
        let session = FocusedDataDifference(previous: a, current: b)
        try await XCTUnwrap(session.find()).value
        XCTAssertEqual(session.phase, .paused); XCTAssertNil(session.position)
        try await XCTUnwrap(session.advance()).value
        XCTAssertEqual(session.position?.byteOffset, 16385)
        XCTAssertEqual(session.position?.previousLabel, "End of data")
        let revision = session.revision
        session.reveal(); XCTAssertNotEqual(session.revision, revision)
        XCTAssertNil(session.advance())
        session.cancel(); XCTAssertNil(session.position)
        try await XCTUnwrap(session.find()).value
        XCTAssertEqual(session.phase, .paused)
        let equal = FocusedDataDifference(previous: Data([0, 0xFF]), current: Data([0, 0xFF]))
        try await XCTUnwrap(equal.find()).value
        XCTAssertEqual(equal.phase, .equal); XCTAssertTrue(equal.message.contains("No difference"))
    }
    func testDismissedComputedByteResultCannotPublishLate() async throws {
        let gate = DataDifferenceGate()
        let session = FocusedDataDifference(previous: Data([0x7F]), current: Data([0x80]), runner: { cursor in
            var next = cursor; let result = try next.step()
            await gate.wait(); return (next, result)
        })
        let work = try XCTUnwrap(session.find())
        while !(await gate.entered) { await Task.yield() }
        session.cancel(); await gate.release(); await work.value
        XCTAssertNil(session.position); XCTAssertEqual(session.phase, .ready)
        try await XCTUnwrap(session.find()).value
        XCTAssertEqual(session.position?.currentByte, 0x80)
    }
}
private actor DataDifferenceGate {
    var entered = false
    private var open = false
    private var waiter: CheckedContinuation<Void, Never>?
    func wait() async { entered = true; if !open { await withCheckedContinuation { waiter = $0 } } }
    func release() { open = true; waiter?.resume(); waiter = nil }
}
