import AppKit
import XCTest
import EntitlementDiffCore
import EntitlementDiffModel
@testable import EntitlementDiffApp

@MainActor
final class CopyExactKeyTests: XCTestCase {
    private func model(keys: [String]) throws -> ComparisonModel {
        let values = try EntitlementDictionary(entries: keys.map { .init(key: $0, value: .integer(1)) })
        let a = EntitlementSnapshot(sourceName: "Before.app", signingIdentifier: "fixture", architecture: .arm64, entitlements: .init())
        let b = EntitlementSnapshot(sourceName: "After.app", signingIdentifier: "fixture", architecture: .arm64, entitlements: values)
        let saved = try SavedReport.parse(ComparisonReport(previous: a, current: b).jsonData())
        let model = ComparisonModel(reader: UnusedKeyReader())
        model.openSavedComparison(saved)
        return model
    }
    func testNamedNativePasteboardRetainsFullRawBytesForEveryKey() throws {
        let keys = ["é", "e\u{301}", " key \t\n", "control\u{0001}key", "", String(repeating: "longé", count: 200)]
        let model = try model(keys: keys)
        let clipboard = NSPasteboard(name: .init("EntitlementDiff-copy-key-" + UUID().uuidString))
        defer { clipboard.releaseGlobally() }
        let actions = AppActions(model: model, writeExactKey: { key in
            clipboard.clearContents()
            return clipboard.setData(Data(key.utf8), forType: .string)
        })
        let report = try XCTUnwrap(model.report).jsonData()
        for key in keys {
            _ = model.browser.findExactKey(key)
            XCTAssertTrue(actions.canCopyExactKey)
            actions.copyExactKey()
            XCTAssertEqual(clipboard.data(forType: .string), Data(key.utf8))
            XCTAssertTrue(actions.statusMessage.contains("raw UTF-8"))
        }
        XCTAssertEqual(try model.report?.jsonData(), report)
        XCTAssertTrue(model.previous.snapshot?.isSavedBaseline == true)
    }
    func testActionReadsCurrentSelectionAndDoesNothingAfterFilterOrClear() throws {
        let model = try model(keys: ["first", "second"])
        var copied: [String] = []
        let actions = AppActions(model: model, writeExactKey: { copied.append($0); return true })
        XCTAssertFalse(actions.canCopyExactKey)
        _ = model.browser.findExactKey("first")
        _ = model.browser.findExactKey("second")
        actions.copyExactKey()
        XCTAssertEqual(copied, ["second"])
        model.browser.query = "first"
        XCTAssertFalse(actions.canCopyExactKey)
        actions.copyExactKey(); XCTAssertEqual(copied, ["second"])
        _ = model.browser.findExactKey("first")
        actions.isFindingEntitlement = true
        actions.copyExactKey(); XCTAssertEqual(copied, ["second"])
        actions.isFindingEntitlement = false
        model.clear()
        actions.copyExactKey(); XCTAssertEqual(copied, ["second"])
        XCTAssertFalse(actions.canCopyExactKey)
    }
    func testClipboardFailureDoesNotClaimSuccess() throws {
        let model = try model(keys: ["key"])
        let actions = AppActions(model: model, writeExactKey: { _ in false })
        _ = model.browser.findExactKey("key")
        actions.copyExactKey()
        XCTAssertEqual(actions.errorMessage, "The system clipboard did not accept the entitlement key.")
        XCTAssertEqual(actions.statusMessage, "")
    }
}
private struct UnusedKeyReader: SnapshotReading {
    func read(at url: URL, architecture: Architecture) async throws -> EntitlementSnapshot {
        throw CocoaError(.fileReadUnknown)
    }
}
