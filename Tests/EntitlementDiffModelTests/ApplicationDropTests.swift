import Foundation
import XCTest
@testable import EntitlementDiffModel

final class ApplicationDropTests: XCTestCase {
    func testSingleLocalAppRetainsExactURLWithoutFilesystemRead() throws {
        let url = URL(fileURLWithPath: "/not-created/Build ; quote' space.APP", isDirectory: true)
        XCTAssertEqual(try ApplicationDrop.applicationURL(from: [url]), url)
    }
    func testRejectsEmptyAndMultipleItemsRatherThanChoosingOne() {
        let app = URL(fileURLWithPath: "/unused/A.app")
        for urls in [[], [app, app]] {
            XCTAssertThrowsError(try ApplicationDrop.applicationURL(from: urls)) { error in
                guard case ApplicationDropError.oneApplicationRequired = error else { return XCTFail("Wrong drop error") }
            }
        }
    }
    func testRejectsWebURLsRemoteHostsAndNonAppFiles() {
        for url in [URL(string: "https://example.com/A.app")!, URL(string: "file://remote/A.app")!, URL(fileURLWithPath: "/unused/report.json"), URL(fileURLWithPath: "/unused/folder")] {
            XCTAssertThrowsError(try ApplicationDrop.applicationURL(from: [url])) { error in
                guard case ApplicationDropError.localApplicationRequired = error else { return XCTFail("Wrong drop error") }
            }
        }
    }
}
