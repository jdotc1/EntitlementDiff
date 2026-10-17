import AppKit
import XCTest
import EntitlementDiffCore
import EntitlementDiffModel
@testable import EntitlementDiffApp

@MainActor
final class LeafCopyActionTests: XCTestCase {
    func testSideSpecificCompleteCopyAndCapturedSession() async throws {
        let model = ComparisonModel(reader: UnusedLeafReader(), architecture: .arm64)
        model.loadExample(structured: true)
        let report = try XCTUnwrap(model.report)
        let beforeJSON = try report.jsonData()
        let change = try XCTUnwrap(model.rows.first)
        let row = try XCTUnwrap(ValueInspector(previous: change.previous, current: change.current, expanded: ["root"])
            .rows.first { $0.previous?.typeName == "String" && $0.current?.typeName == "String" })
        let actions = AppActions(model: model)
        actions.inspectValue(change, row: row)
        XCTAssertTrue(actions.isBusy)
        actions.swap()
        actions.clear()
        XCTAssertEqual(try model.report?.jsonData(), beforeJSON)
        let captured = try XCTUnwrap(actions.focusedValue)
        let clipboard = NSPasteboard.withUniqueName()
        defer { clipboard.releaseGlobally() }
        let previous = try XCTUnwrap(actions.copyLeaf(.previous, to: clipboard))
        XCTAssertTrue(actions.isWritingReport)
        XCTAssertNil(actions.copyLeaf(.current, to: clipboard))
        await previous.value
        XCTAssertFalse(actions.isWritingReport)
        let previousJSON = try XCTUnwrap(clipboard.string(forType: .string))
        XCTAssertEqual(previousJSON, String(decoding: try XCTUnwrap(InspectorLeaf(captured.previous)).jsonData(), as: UTF8.self))
        XCTAssertTrue(previousJSON.contains("PREVIOUS END"))
        XCTAssertFalse(previousJSON.contains("CURRENT END"))
        // Even an external model mutation cannot silently retarget the open viewer's copy.
        model.loadExample()
        let current = try XCTUnwrap(actions.copyLeaf(.current, to: clipboard))
        await current.value
        let currentJSON = try XCTUnwrap(clipboard.string(forType: .string))
        XCTAssertTrue(currentJSON.contains("CURRENT END"))
        XCTAssertFalse(currentJSON.contains("PREVIOUS END"))
        XCTAssertTrue(actions.statusMessage.contains("current leaf JSON copied"))
        actions.focusedValue = nil
        XCTAssertFalse(actions.isBusy)
        XCTAssertNil(actions.copyLeaf(.current, to: clipboard))
    }

    func testAbsentAndContainerSidesCannotCopyAndEncodingFailureRecovers() async throws {
        let actions = AppActions(model: ComparisonModel(reader: UnusedLeafReader()))
        let clipboard = NSPasteboard.withUniqueName()
        defer { clipboard.releaseGlobally() }
        clipboard.setString("preserve", forType: .string)
        actions.focusedValue = .init(entitlementKey: "test", pathPreview: "Value",
                                     previous: nil, current: .array([]))
        XCTAssertNil(actions.copyLeaf(.previous, to: clipboard))
        XCTAssertNil(actions.copyLeaf(.current, to: clipboard))
        actions.focusedValue = .init(entitlementKey: "test", pathPreview: "Value",
                                     previous: .real(.nan), current: .boolean(false))
        let failed = try XCTUnwrap(actions.copyLeaf(.previous, to: clipboard))
        await failed.value
        XCTAssertFalse(actions.isWritingReport)
        XCTAssertTrue(actions.statusMessage.contains("Could not copy leaf JSON"))
        XCTAssertEqual(clipboard.string(forType: .string), "preserve")
        let recovered = try XCTUnwrap(actions.copyLeaf(.current, to: clipboard))
        await recovered.value
        XCTAssertFalse(actions.isWritingReport)
        XCTAssertTrue(actions.statusMessage.contains("current leaf JSON copied"))
        XCTAssertTrue(try XCTUnwrap(clipboard.string(forType: .string)).contains("boolean"))
    }
}

private actor UnusedLeafReader: SnapshotReading {
    func read(at url: URL, architecture: Architecture) async throws -> EntitlementSnapshot {
        throw CancellationError()
    }
}
