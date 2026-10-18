import Foundation
import XCTest
import EntitlementDiffCore
@testable import EntitlementDiffApp

@MainActor
final class ScalarStepTests: XCTestCase {
    private func document(_ text:String) throws -> LeafValueDocument {
        try LeafValueDocument(leaf:XCTUnwrap(InspectorLeaf(.string(text))))
    }
    func testPageBoundaryExactUTF8AndCopyFollowSteps() throws {
        let doc=try document(String(repeating:"🙂",count:512)+"e\u{301}\u{200B}")
        var nav=StringScalarNavigation();nav.setInput("512");XCTAssertTrue(nav.go(document:doc))
        XCTAssertEqual(nav.position?.pageIndex,0)
        XCTAssertTrue(nav.step(.next,document:doc));XCTAssertEqual(nav.position?.pageIndex,1)
        XCTAssertEqual(nav.position?.scalar,Unicode.Scalar(101));XCTAssertEqual(nav.position?.byteOffset,2048)
        XCTAssertTrue(nav.step(.next,document:doc));XCTAssertEqual(nav.position?.scalar,Unicode.Scalar(0x301))
        XCTAssertEqual(nav.position?.byteOffset,2049);XCTAssertEqual(nav.input,"514")
        XCTAssertTrue(try XCTUnwrap(nav.copyText(side:.previous)).contains("UTF-8: CC 81"))
        XCTAssertTrue(nav.step(.previous,document:doc));XCTAssertTrue(nav.step(.previous,document:doc))
        XCTAssertEqual(nav.position?.pageIndex,0);XCTAssertEqual(nav.position?.byteOffset,2044)
        XCTAssertTrue(try XCTUnwrap(nav.copyText(side:.previous)).contains("F0 9F 99 82"))
    }
    func testFirstEOFEmptyAndNoWrap() throws {
        let doc=try document("é")
        var nav=StringScalarNavigation();XCTAssertFalse(nav.canStep(.next,document:doc));XCTAssertFalse(nav.step(.next,document:doc))
        nav.setInput("1");XCTAssertTrue(nav.go(document:doc));let firstRevision=nav.revision
        XCTAssertFalse(nav.canStep(.previous,document:doc));XCTAssertFalse(nav.step(.previous,document:doc));XCTAssertEqual(nav.revision,firstRevision)
        XCTAssertTrue(nav.step(.next,document:doc));XCTAssertNil(nav.position?.scalar);XCTAssertEqual(nav.position?.byteOffset,2)
        let eof=nav.position, revision=nav.revision
        XCTAssertFalse(nav.step(.next,document:doc));XCTAssertEqual(nav.position,eof);XCTAssertEqual(nav.revision,revision)
        XCTAssertTrue(nav.step(.previous,document:doc));XCTAssertEqual(nav.position?.scalar,Unicode.Scalar(0xE9))
        let empty=try document("");nav.setInput("1");XCTAssertTrue(nav.go(document:empty))
        XCTAssertFalse(nav.canStep(.previous,document:empty));XCTAssertFalse(nav.canStep(.next,document:empty))
    }
    func testPendingRejectedInputIndependentPanesAndReset() throws {
        let doc=try document("aé🙂")
        var left=StringScalarNavigation(),right=StringScalarNavigation()
        left.setInput("2");XCTAssertTrue(left.go(document:doc));right.setInput("3");XCTAssertTrue(right.go(document:doc));let saved=right.position
        left.setInput("999");XCTAssertFalse(left.go(document:doc));XCTAssertNotNil(left.error)
        XCTAssertTrue(left.step(.next,document:doc));XCTAssertEqual(left.input,"3");XCTAssertNil(left.error);XCTAssertEqual(left.position?.byteOffset,3)
        left.setInput("1");XCTAssertTrue(left.step(.previous,document:doc));XCTAssertEqual(left.input,"2")
        XCTAssertEqual(right.position,saved);left.reset();XCTAssertFalse(left.canStep(.next,document:doc));XCTAssertNil(left.copyText(side:.previous))
    }
    func testSteppingDoesNotChangeSearchOrDifference() async throws {
        let difference=FocusedStringDifference(previous:"aéZ",current:"🙂xY");try await XCTUnwrap(difference.find()).value
        let search=FocusedStringSearch(source:"aéZ");search.setQuery(.init(value:"é"));try await XCTUnwrap(search.find()).value
        let details=difference.copyDetails, revision=difference.revision, match=search.match, query=search.input
        let doc=try document("aéZ");var nav=StringScalarNavigation();nav.setInput("2");XCTAssertTrue(nav.go(document:doc))
        XCTAssertTrue(nav.step(.next,document:doc));XCTAssertTrue(nav.step(.previous,document:doc))
        XCTAssertEqual(difference.copyDetails,details);XCTAssertEqual(difference.revision,revision);XCTAssertEqual(search.match,match);XCTAssertEqual(search.input,query)
    }
}
