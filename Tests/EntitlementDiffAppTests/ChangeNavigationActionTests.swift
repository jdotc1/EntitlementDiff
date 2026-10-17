import XCTest
import EntitlementDiffCore
import EntitlementDiffModel
@testable import EntitlementDiffApp

@MainActor
final class ChangeNavigationActionTests: XCTestCase {
    func testActionRevealsCurrentTargetAndBusyOrEmptyStatesCannotMove() throws {
        let model = ComparisonModel(reader: NavigationUnusedReader()), actions = AppActions(model: model)
        XCTAssertFalse(actions.canMoveToChange(.next))
        model.loadExample()
        let before = try XCTUnwrap(model.report).jsonData(), revision = model.reportRevision
        model.browser.sortOrder = [.init(column: .key, order: .reverse)]
        let first = model.browser.visibleRows[0].id
        actions.moveToChange(.next)
        XCTAssertEqual(model.browser.selection, first); XCTAssertEqual(actions.findRevealID, first)
        let reveal = actions.findRevealRevision
        actions.isFindingEntitlement = true
        actions.moveToChange(.next)
        XCTAssertEqual(model.browser.selection, first); XCTAssertEqual(actions.findRevealRevision, reveal)
        actions.isFindingEntitlement = false
        model.browser.query = "network.client"
        actions.moveToChange(.previous)
        XCTAssertEqual(model.browser.selectedRow?.key, "com.apple.security.network.client")
        XCTAssertNotEqual(actions.findRevealRevision, reveal)
        XCTAssertEqual(try model.report?.jsonData(), before); XCTAssertEqual(model.reportRevision, revision)
        model.clear()
        actions.moveToChange(.next)
        XCTAssertNil(model.browser.selection); XCTAssertFalse(actions.canMoveToChange(.next))
    }
}
private struct NavigationUnusedReader: SnapshotReading {
    func read(at url: URL, architecture: Architecture) async throws -> EntitlementSnapshot { throw CancellationError() }
}
