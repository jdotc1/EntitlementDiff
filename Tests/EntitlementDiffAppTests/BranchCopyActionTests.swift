import AppKit
import XCTest
import EntitlementDiffCore
import EntitlementDiffModel
@testable import EntitlementDiffApp

@MainActor
final class BranchCopyActionTests: XCTestCase {
    private func selected() throws -> (ComparisonModel, AppActions, String) {
        let model = ComparisonModel(reader: UnusedBranchReader())
        model.loadExample()
        let row = try XCTUnwrap(model.browser.visibleRows.first)
        model.browser.selection = row.id
        return (model, AppActions(model: model), row.id)
    }

    func testLaterPageCopyRetainsWholeTypedContainerAndDirection() async throws {
        let (model, actions, id) = try selected()
        let entries = (0..<115).map { EntitlementEntry(key: String(format: "k%03d", $0), value: .integer(Int64($0))) }
        let dictionary = try EntitlementDictionary(entries: entries + [
            .init(key: "é", value: .unsignedInteger(UInt64.max)),
            .init(key: "e\u{301}", value: .boolean(false)),
            .init(key: "ordered", value: .array([.string("z"), .string("a"), .string("z")]))])
        var navigation = InspectorBranchNavigator(previous: .dictionary(dictionary), current: .array([.boolean(true), .integer(-1)]))
        // Enter the previous structure, then copy beyond the first 50 children.
        XCTAssertTrue(navigation.enter("root/previous"))
        navigation.nextPage()
        XCTAssertEqual(navigation.offset, 50)
        let board = NSPasteboard.withUniqueName()
        defer { board.releaseGlobally() }
        let reportBefore = try XCTUnwrap(model.report).jsonData()
        let task = try XCTUnwrap(actions.copyBranch(.previous, row: navigation.root, entitlementID: id,
                                                  comparisonRevision: model.reportRevision, to: board))
        XCTAssertTrue(actions.isCopyingBranch)
        XCTAssertTrue(actions.isBusy)
        XCTAssertNil(actions.copyBranch(.previous, row: navigation.root, entitlementID: id,
                                       comparisonRevision: model.reportRevision, to: board))
        actions.swap()
        XCTAssertEqual(try XCTUnwrap(model.report).jsonData(), reportBefore)
        await task.value
        XCTAssertFalse(actions.isCopyingBranch)
        let text = try XCTUnwrap(board.string(forType: .string))
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(text.utf8)) as? [String: Any])
        XCTAssertEqual(object["type"] as? String, "dictionary")
        let values = try XCTUnwrap(object["value"] as? [[String: Any]])
        XCTAssertEqual(values.count, 118)
        XCTAssertTrue(text.contains("k000")); XCTAssertTrue(text.contains("k114"))
        XCTAssertTrue(text.contains("18446744073709551615"))
        let rawKeys = values.compactMap { $0["key"] as? String }.map { Array($0.utf8) }
        XCTAssertTrue(rawKeys.contains(Array("é".utf8)))
        XCTAssertTrue(rawKeys.contains(Array("e\u{301}".utf8)))
        let ordered = try XCTUnwrap(values.first { ($0["key"] as? String) == "ordered" }?["value"] as? [String: Any])
        XCTAssertEqual((ordered["value"] as? [[String: Any]])?.compactMap { $0["value"] as? String }, ["z", "a", "z"])
        navigation.back()
        let current = try XCTUnwrap(actions.copyBranch(.current, row: navigation.root, entitlementID: id,
                                                     comparisonRevision: model.reportRevision, to: board))
        await current.value
        XCTAssertTrue(try XCTUnwrap(board.string(forType: .string)).contains("boolean"))
        XCTAssertFalse(try XCTUnwrap(board.string(forType: .string)).contains("k114"))
        XCTAssertEqual(try XCTUnwrap(model.report).jsonData(), reportBefore)
    }

    func testEmptyAbsentScalarAndEncodingFailurePreserveClipboard() async throws {
        let (model, actions, id) = try selected()
        let board = NSPasteboard.withUniqueName()
        defer { board.releaseGlobally() }
        board.setString("preserve", forType: .string)
        let row = InspectorBranchNavigator(previous: nil, current: .integer(3)).root
        for side in ComparisonSide.allCases {
            XCTAssertNil(actions.copyBranch(side, row: row, entitlementID: id,
                                            comparisonRevision: model.reportRevision, to: board))
        }
        let failedRow = InspectorBranchNavigator(previous: .array([.real(.nan)]), current: .dictionary(.init())).root
        try await XCTUnwrap(actions.copyBranch(.previous, row: failedRow, entitlementID: id,
                                              comparisonRevision: model.reportRevision, to: board)).value
        XCTAssertEqual(board.string(forType: .string), "preserve")
        XCTAssertFalse(actions.isBusy)
        XCTAssertTrue(actions.statusMessage.contains("Could not copy branch JSON"))
        try await XCTUnwrap(actions.copyBranch(.current, row: failedRow, entitlementID: id,
                                              comparisonRevision: model.reportRevision, to: board)).value
        XCTAssertTrue(try XCTUnwrap(board.string(forType: .string)).contains("dictionary"))
        XCTAssertFalse(actions.isBusy)
    }

    func testStaleOwnershipAndSupersededCopyDoNotWrite() async throws {
        let (model, actions, id) = try selected()
        let row = InspectorBranchNavigator(previous: .array([]), current: nil).root
        let board = NSPasteboard.withUniqueName()
        defer { board.releaseGlobally() }
        board.setString("preserve", forType: .string)
        XCTAssertNil(actions.copyBranch(.previous, row: row, entitlementID: id, comparisonRevision: UUID(), to: board))
        XCTAssertNil(actions.copyBranch(.previous, row: row, entitlementID: "wrong", comparisonRevision: model.reportRevision, to: board))
        let work = try XCTUnwrap(actions.copyBranch(.previous, row: row, entitlementID: id,
                                                  comparisonRevision: model.reportRevision, to: board))
        model.loadExample() // Explicit external mutation bypassing UI busy guard.
        await work.value
        XCTAssertEqual(board.string(forType: .string), "preserve")
        XCTAssertTrue(actions.statusMessage.contains("was not copied"))
        XCTAssertFalse(actions.isBusy)
    }
}

private actor UnusedBranchReader: SnapshotReading {
    func read(at url: URL, architecture: Architecture) async throws -> EntitlementSnapshot { throw CancellationError() }
}
