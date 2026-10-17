import Foundation
import XCTest
import EntitlementDiffCore
@testable import EntitlementDiffModel

@MainActor
final class SavedBaselineTests: XCTestCase {
    private func snapshot(_ architecture: Architecture = .arm64) -> EntitlementSnapshot {
        .init(sourceName: "Saved.app", signingIdentifier: "saved", architecture: architecture,
              entitlements: .init(["value": .integer(7)]))
    }
    func testAdoptionClearsURLsCurrentAndSuppressesPendingReads() async throws {
        let reader = BaselineReader(), model = ComparisonModel(reader: BaselineReader())
        // Use a separately controlled model to finish superseded requests deterministically.
        let controlled = ComparisonModel(reader: reader)
        let a = controlled.load(URL(fileURLWithPath: "/live/Old.app"), side: .previous)
        let old = await reader.next()
        let b = controlled.load(URL(fileURLWithPath: "/live/New.app"), side: .current)
        let new = await reader.next()
        controlled.useSavedBaseline(snapshot(.x86_64))
        await reader.finish(old, value: 1); await reader.finish(new, value: 2)
        await a.value; await b.value
        XCTAssertEqual(controlled.architecture, .x86_64)
        XCTAssertEqual(controlled.previous.snapshot?.entitlements["value"], .integer(7))
        XCTAssertEqual(controlled.previous.snapshot?.isSavedBaseline, true)
        XCTAssertTrue(controlled.current.isEmpty)
        XCTAssertNil(controlled.report)
        XCTAssertTrue(controlled.selectedSourceURLs.isEmpty)
        XCTAssertFalse(controlled.canReload(.previous))
        XCTAssertFalse(controlled.canReloadBoth)
        XCTAssertNil(model.report)
    }
    func testFreshCurrentComparisonSwapAndClearRetainProvenanceWithoutPaths() async throws {
        let reader = BaselineReader(), model = ComparisonModel(reader: BaselineReader())
        model.loadExample()
        let old = try XCTUnwrap(model.report).jsonData()
        XCTAssertThrowsError(try SavedReport.parse(Data("invalid".utf8)))
        XCTAssertEqual(try model.report?.jsonData(), old)
        let controlled = ComparisonModel(reader: reader)
        controlled.useSavedBaseline(snapshot())
        let task = controlled.load(URL(fileURLWithPath: "/session-only/Current.app"), side: .current)
        let request = await reader.next(); await reader.finish(request, value: 9); await task.value
        XCTAssertEqual(controlled.report?.changes.count, 1)
        XCTAssertTrue(try XCTUnwrap(controlled.report).notices.contains { $0.contains("saved-report") })
        XCTAssertFalse(String(decoding: try XCTUnwrap(controlled.report).jsonData(), as: UTF8.self).contains("/session-only"))
        XCTAssertTrue(controlled.swap())
        XCTAssertEqual(controlled.current.snapshot?.isSavedBaseline, true)
        XCTAssertFalse(controlled.canReload(.current))
        XCTAssertTrue(controlled.canReload(.previous))
        controlled.clear(); XCTAssertTrue(controlled.selectedSourceURLs.isEmpty)
        XCTAssertNil(controlled.report)
    }
}

private actor BaselineReader: SnapshotReading {
    struct Request: Sendable { let id: UUID; let url: URL; let architecture: Architecture }
    private var queue: [Request] = []
    private var consumers: [CheckedContinuation<Request, Never>] = []
    private var completions: [UUID: CheckedContinuation<EntitlementSnapshot, any Error>] = [:]
    func read(at url: URL, architecture: Architecture) async throws -> EntitlementSnapshot {
        try await withCheckedThrowingContinuation { completion in
            let request = Request(id: UUID(), url: url, architecture: architecture)
            completions[request.id] = completion
            if consumers.isEmpty { queue.append(request) } else { consumers.removeFirst().resume(returning: request) }
        }
    }
    func next() async -> Request {
        if !queue.isEmpty { return queue.removeFirst() }
        return await withCheckedContinuation { consumers.append($0) }
    }
    func finish(_ request: Request, value: Int64) {
        completions.removeValue(forKey: request.id)?.resume(returning: .init(
            sourceName: request.url.lastPathComponent, signingIdentifier: "test", architecture: request.architecture,
            entitlements: .init(["value": .integer(value)])))
    }
    func fail(_ request: Request) {
        completions.removeValue(forKey: request.id)?.resume(throwing: Failure())
    }
    struct Failure: LocalizedError { var errorDescription: String? { "Temporarily unavailable" } }
}
