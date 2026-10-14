import Foundation
import XCTest
import EntitlementDiffCore
import EntitlementDiffModel
@testable import EntitlementDiffApp

@MainActor
final class AppDropActionTests: XCTestCase {
    func testValidDropUsesChosenSideAndExplicitArchitecture() async throws {
        let reader = DropReader()
        let model = ComparisonModel(reader: reader, architecture: .x86_64)
        model.loadExample()
        let actions = AppActions(model: model)
        let url = URL(fileURLWithPath: "/unused/Dropped.app")
        XCTAssertTrue(actions.drop([url], side: .current))
        XCTAssertTrue(model.current.isLoading)
        XCTAssertNil(model.report)
        XCTAssertEqual(model.previous.snapshot?.origin, .syntheticExample)
        let request = await reader.request()
        XCTAssertEqual(request.0, url)
        XCTAssertEqual(request.1, .x86_64)
        model.clear()
        await reader.finish()
    }

    func testRejectedEnvelopePreservesInputsAndShowsError() {
        let model = ComparisonModel(reader: DropReader(), architecture: .arm64)
        model.loadExample()
        let actions = AppActions(model: model)
        XCTAssertFalse(actions.drop([URL(fileURLWithPath: "/unused/a.json")], side: .previous))
        XCTAssertNotNil(actions.errorMessage)
        XCTAssertNotNil(model.report)
        XCTAssertEqual(model.previous.snapshot?.origin, .syntheticExample)
        XCTAssertFalse(model.isLoading)
    }

    func testEmptyAndMultipleDropsPreserveComparison() {
        let model = ComparisonModel(reader: DropReader())
        model.loadExample()
        let actions = AppActions(model: model)
        XCTAssertFalse(actions.drop([], side: .previous))
        XCTAssertFalse(actions.drop([URL(fileURLWithPath: "/a.app"), URL(fileURLWithPath: "/b.app")], side: .previous))
        XCTAssertNotNil(model.report)
    }
}

private actor DropReader: SnapshotReading {
    private var received: (URL, Architecture)?
    private var waiter: CheckedContinuation<(URL, Architecture), Never>?
    private var completion: CheckedContinuation<EntitlementSnapshot, Error>?
    func read(at url: URL, architecture: Architecture) async throws -> EntitlementSnapshot {
        received = (url, architecture)
        waiter?.resume(returning: (url, architecture))
        waiter = nil
        return try await withCheckedThrowingContinuation { completion = $0 }
    }
    func request() async -> (URL, Architecture) {
        if let received { return received }
        return await withCheckedContinuation { waiter = $0 }
    }
    func finish() {
        completion?.resume(throwing: CancellationError())
        completion = nil
    }
}
