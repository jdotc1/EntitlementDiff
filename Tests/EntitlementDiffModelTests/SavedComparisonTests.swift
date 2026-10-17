import Foundation
import XCTest
import EntitlementDiffCore
@testable import EntitlementDiffModel

@MainActor
final class SavedComparisonTests: XCTestCase {
    private func saved() throws -> SavedReport {
        let pair = ExampleSnapshots.pair(architecture: .x86_64)
        return try SavedReport.parse(ComparisonReport(previous: pair.previous, current: pair.current).jsonData())
    }
    func testOpeningPairSuppressesPendingReadsAndPublishesCompleteSavedComparison() async throws {
        let reader = SavedPairReader(), model = ComparisonModel(reader: SavedPairReader(), architecture: .arm64)
        let controlled = ComparisonModel(reader: reader, architecture: .arm64)
        let a = controlled.load(URL(fileURLWithPath: "/old-live/Old.app"), side: .previous)
        let old = await reader.next()
        let b = controlled.load(URL(fileURLWithPath: "/old-live/New.app"), side: .current)
        let new = await reader.next()
        let revision = controlled.reportRevision, saved = try saved()
        controlled.openSavedComparison(saved)
        await reader.finish(old, value: 1); await reader.finish(new, value: 2)
        await a.value; await b.value
        XCTAssertEqual(controlled.architecture, .x86_64)
        XCTAssertNotEqual(controlled.reportRevision, revision)
        XCTAssertEqual(controlled.previous.snapshot?.sourceName, saved.previous.sourceName)
        XCTAssertEqual(controlled.current.snapshot?.entitlements, saved.current.entitlements)
        XCTAssertTrue(controlled.previous.snapshot?.isSavedBaseline == true)
        XCTAssertTrue(controlled.current.snapshot?.isSavedBaseline == true)
        XCTAssertTrue(controlled.selectedSourceURLs.isEmpty)
        XCTAssertFalse(controlled.canReload(.previous)); XCTAssertFalse(controlled.canReload(.current))
        XCTAssertEqual(controlled.browser.count(.allKeys), 6)
        XCTAssertEqual(controlled.browser.visibleRows.count, 5)
        XCTAssertEqual(try controlled.report?.jsonData(), try ComparisonReport(previous: saved.previous, current: saved.current).jsonData())
        XCTAssertNil(model.report)
    }
    func testSavedPairFiltersSwapAndLiveReplacementKeepProvenanceAndReportFidelity() async throws {
        let reader = SavedPairReader(), model = ComparisonModel(reader: reader)
        let saved = try saved(); model.openSavedComparison(saved)
        let full = try XCTUnwrap(model.report).jsonData()
        model.browser.filter = .unchanged
        XCTAssertEqual(model.browser.visibleRows.count, 1)
        XCTAssertEqual(try model.report?.jsonData(), full)
        model.browser.selection = model.browser.visibleRows.first?.id
        XCTAssertTrue(model.swap())
        XCTAssertTrue(model.current.snapshot?.isSavedBaseline == true)
        let requestTask = model.load(URL(fileURLWithPath: "/session-only/Fresh.app"), side: .current)
        let request = await reader.next()
        XCTAssertNil(model.report)
        XCTAssertNil(model.browser.selection)
        await reader.finish(request, value: 3); await requestTask.value
        XCTAssertEqual(model.previous.snapshot?.isSavedBaseline, true)
        XCTAssertEqual(model.current.snapshot?.isSavedBaseline, false)
        XCTAssertTrue(model.canReload(.current)); XCTAssertFalse(model.canReload(.previous))
        let report = try XCTUnwrap(model.report), data = try report.jsonData()
        XCTAssertTrue(report.notices.contains { $0.contains("saved-report") })
        XCTAssertFalse(String(decoding: data, as: UTF8.self).contains("/session-only"))
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertEqual(json["schemaVersion"] as? Int, 1)
        model.setArchitecture(.arm64)
        XCTAssertNil(model.report); XCTAssertTrue(model.selectedSourceURLs.isEmpty)
    }
}

private actor SavedPairReader: SnapshotReading {
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
