import XCTest
import EntitlementDiffCore
@testable import EntitlementDiffModel

final class ComparisonGuidanceTests: XCTestCase {
    private func ready(saved: Bool = false) -> InputState {
        .ready(EntitlementSnapshot(sourceName: "App", signingIdentifier: "example", architecture: .arm64,
                                   entitlements: EntitlementDictionary(), isSavedBaseline: saved))
    }

    func testEmptyOffersBothInputsAndSavedReport() {
        let guidance = ComparisonGuidance(previous: .empty, current: .empty)
        XCTAssertEqual(guidance.actions, [.choose(.previous), .choose(.current), .openSavedReport])
        XCTAssertTrue(guidance.title.contains("saved report"))
    }

    func testReadySideRequestsOnlyMissingSideAndRecognizesSavedBaseline() {
        let live = ComparisonGuidance(previous: ready(), current: .empty)
        let saved = ComparisonGuidance(previous: ready(saved: true), current: .empty)
        XCTAssertEqual(live.actions, [.choose(.current)])
        XCTAssertFalse(live.title.contains("saved baseline"))
        XCTAssertTrue(saved.title.contains("saved baseline"))
        XCTAssertEqual(saved.actions, live.actions)
        XCTAssertEqual(ComparisonGuidance(previous: .empty, current: ready()).actions, [.choose(.previous)])
    }

    func testFailuresOfferRetryOnlyWithRetainedSourceAndNeverClaimReadiness() {
        let failed = InputState.failed(sourceName: "Broken.app", message: "Cannot read")
        let one = ComparisonGuidance(previous: failed, current: ready(), retryableSides: [.previous])
        XCTAssertEqual(one.actions, [.retry(.previous), .choose(.previous)])
        XCTAssertTrue(one.title.contains("failed"))
        XCTAssertEqual(ComparisonGuidance(previous: failed, current: .empty).actions,
                       [.choose(.previous), .choose(.current)])
        XCTAssertEqual(ComparisonGuidance(previous: failed, current: failed, retryableSides: [.previous, .current]).actions,
                       [.retry(.previous), .choose(.previous), .retry(.current), .choose(.current)])
    }

    func testLoadingNamesSidesAndTakesPrecedenceOverFailure() {
        let loading = InputState.loading(sourceName: "App")
        let one = ComparisonGuidance(previous: .failed(sourceName: "Bad", message: "Error"), current: loading)
        XCTAssertEqual(one.title, "Reading Current input…")
        XCTAssertEqual(one.actions, [.cancel])
        XCTAssertEqual(ComparisonGuidance(previous: loading, current: loading).title, "Reading Previous and Current input…")
    }

    func testReportFailureIsDistinctFromMissingInputs() {
        let guidance = ComparisonGuidance(previous: ready(), current: ready(), reportError: "Architecture mismatch")
        XCTAssertEqual(guidance.title, "Comparison unavailable")
        XCTAssertEqual(guidance.message, "Architecture mismatch")
        XCTAssertEqual(guidance.actions, [.choose(.previous), .choose(.current)])
    }
}
