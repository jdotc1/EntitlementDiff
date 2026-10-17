import Foundation
import XCTest
@testable import EntitlementDiffCore

final class ReportDestinationTests: XCTestCase {
    func testRejectsWritesInsideSelectedApplication() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let app = root.appendingPathComponent("Selected.app", isDirectory: true)
        try FileManager.default.createDirectory(at: app.appendingPathComponent("Contents"), withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        for destination in [app.appendingPathComponent("Contents/report.json"), app] {
            XCTAssertThrowsError(try ReportDestination.validate(destination, excluding: [app])) { error in
                guard case ReportDestinationError.insideInputBundle = error else {
                    return XCTFail("Expected input-bundle rejection, not an unrelated missing-parent error: \(error)")
                }
            }
        }
    }
    func testDoesNotRejectSiblingWithCommonPrefix() {
        let app = URL(fileURLWithPath: "/tmp/Selected.app", isDirectory: true)
        XCTAssertNoThrow(try ReportDestination.validate(URL(fileURLWithPath: "/tmp/Selected.app-report.json"), excluding: [app]))
    }
    func testRejectsSymlinkIntoSelectedApplication() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let app = root.appendingPathComponent("Selected.app", isDirectory: true)
        try FileManager.default.createDirectory(at: app, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let alias = root.appendingPathComponent("Alias", isDirectory: true)
        try FileManager.default.createSymbolicLink(at: alias, withDestinationURL: app)
        XCTAssertThrowsError(try ReportDestination.validate(alias.appendingPathComponent("report.json"), excluding: [app])) { error in
            guard case ReportDestinationError.insideInputBundle = error else {
                return XCTFail("Expected input-bundle rejection, got: \(error)")
            }
        }
    }
    func testProtectsEntryAncestryIndependentlyOfResolvedTarget() {
        // Synthetic URLs exercise ancestry policy without a link or write fixture.
        let input = URL(fileURLWithPath: "/phase1-policy/Selected.app")
        let entry = input.appendingPathComponent("Contents/report.json")
        let target = URL(fileURLWithPath: "/phase1-policy/Reports/report.json")
        XCTAssertThrowsError(try ReportDestination.validate(entryURL: entry, resolvedTargetURL: target, excluding: [input])) { error in
            guard case ReportDestinationError.insideInputBundle = error else {
                return XCTFail("Expected input-entry rejection, got: \(error)")
            }
        }
    }

}
