import Foundation
import XCTest
import EntitlementDiffCore
@testable import EntitlementDiffApp

@MainActor
final class StringScalarNavigationTests: XCTestCase {
    private func document(_ text: String) throws -> LeafValueDocument {
        try LeafValueDocument(leaf:XCTUnwrap(InspectorLeaf(.string(text))))
    }
    func testExactScalarsUTF8AndPageBoundaries() throws {
        let doc = try document(String(repeating:"🙂",count:512)+"e\u{301}\u{200B}\n")
        XCTAssertEqual(doc.stringScalarCount,516)
        for (offset,byte,scalar) in [(511,2044,Unicode.Scalar(0x1F642)),(512,2048,Unicode.Scalar(0x65)),(513,2049,Unicode.Scalar(0x301)),(514,2051,Unicode.Scalar(0x200B)),(515,2054,Unicode.Scalar(10))] {
            let p = try XCTUnwrap(doc.scalarPosition(at:offset))
            XCTAssertEqual(p.byteOffset,byte);XCTAssertEqual(p.scalar,scalar);XCTAssertEqual(p.pageIndex,offset/512)
            XCTAssertNotNil(doc.stringDifferencePage(onPage:p.pageIndex,byteOffset:p.byteOffset,scalarByteCount:p.byteCount)?.highlight)
        }
        let eof = try XCTUnwrap(doc.scalarPosition(at:516));XCTAssertNil(eof.scalar);XCTAssertEqual(eof.byteOffset,2055)
        XCTAssertNotNil(doc.stringDifferencePage(onPage:1,byteOffset:eof.byteOffset,scalarByteCount:0)?.highlight)
        XCTAssertNil(doc.scalarPosition(at:-1));XCTAssertNil(doc.scalarPosition(at:517))
    }
    func testEmptyAndExactFullPageEOF() throws {
        for text in ["",String(repeating:"a",count:512)] {
            let doc = try document(text), count = try XCTUnwrap(doc.stringScalarCount)
            let eof = try XCTUnwrap(doc.scalarPosition(at:count));XCTAssertNil(eof.scalar);XCTAssertEqual(eof.pageIndex,0)
            XCTAssertNotNil(doc.stringDifferencePage(onPage:0,byteOffset:eof.byteOffset,scalarByteCount:0)?.highlight)
        }
    }
    func testStrictInputLastSuccessfulAndIndependentState() throws {
        let doc = try document("aé🙂"), other = try document("e\u{301}")
        var nav = StringScalarNavigation(), right = StringScalarNavigation()
        nav.setInput("3");XCTAssertTrue(nav.go(document:doc));let saved=nav.position, revision=nav.revision
        for input in ["","0","5","-1","+1"," 1","1 ","١","１","18446744073709551615",String(repeating:"9",count:10000)] {
            nav.setInput(input);XCTAssertLessThanOrEqual(nav.input.utf8.count,21);XCTAssertFalse(nav.go(document:doc))
            XCTAssertEqual(nav.position,saved);XCTAssertEqual(nav.revision,revision)
        }
        right.setInput("2");XCTAssertTrue(right.go(document:other));XCTAssertEqual(right.position?.scalar,Unicode.Scalar(0x301))
        XCTAssertEqual(nav.position,saved)
        nav.setInput("0004");XCTAssertTrue(nav.go(document:doc));XCTAssertNil(nav.position?.scalar)
        nav.reset();XCTAssertNil(nav.position);XCTAssertNil(nav.error);XCTAssertEqual(nav.input,"1")
    }
    func testNavigationLeavesDifferenceAndSearchStateUnchanged() async throws {
        let difference=FocusedStringDifference(previous:"aéZ",current:"🙂\u{200B}Yx")
        try await XCTUnwrap(difference.find()).value
        let search=FocusedStringSearch(source:"aéZ");search.setQuery(.init(value:"é"));try await XCTUnwrap(search.find()).value
        let position=difference.position, revision=difference.revision, copy=difference.copyDetails, match=search.match, query=search.input
        var nav=StringScalarNavigation();nav.setInput("3");XCTAssertTrue(nav.go(document:try document("aéZ")))
        XCTAssertEqual(difference.position,position);XCTAssertEqual(difference.revision,revision);XCTAssertEqual(difference.copyDetails,copy)
        XCTAssertEqual(search.match,match);XCTAssertEqual(search.input,query)
    }
}
