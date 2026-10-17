import XCTest
import EntitlementDiffCore
@testable import EntitlementDiffModel

@MainActor
final class InspectorRevisionTests: XCTestCase {
    func testReplacementAndSwapResetNavigationIdentityButPresentationDoesNot() {
        let model = ComparisonModel(reader: RevisionReader())
        model.loadExample(structured: true)
        let initial = model.reportRevision
        let key = model.rows[0].id
        model.browser.query = "structured"
        XCTAssertEqual(model.reportRevision, initial)
        XCTAssertTrue(model.swap())
        XCTAssertNotEqual(model.reportRevision, initial)
        XCTAssertEqual(model.rows[0].id, key)
        let swapped = model.reportRevision
        model.loadExample(structured: true)
        XCTAssertNotEqual(model.reportRevision, swapped)
        let replaced = model.reportRevision
        model.clear()
        XCTAssertNotEqual(model.reportRevision, replaced)
        XCTAssertNil(model.report)
    }
}
private actor RevisionReader: SnapshotReading {
    func read(at url: URL, architecture: Architecture) async throws -> EntitlementSnapshot { throw CancellationError() }
}
