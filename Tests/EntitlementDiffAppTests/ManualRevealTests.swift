import Foundation
import XCTest
import EntitlementDiffCore
@testable import EntitlementDiffApp

@MainActor final class ManualRevealTests: XCTestCase {
    func testScalarRevealUsesCapturedUnicodeAndEOFInsteadOfPendingInput() throws {
        let document = try LeafValueDocument(leaf: XCTUnwrap(InspectorLeaf(.string(String(repeating: "🙂", count: 512) + "e\u{301}"))))
        var nav = StringScalarNavigation()
        XCTAssertFalse(nav.reveal())
        nav.setInput("514"); XCTAssertTrue(nav.go(document: document))
        let saved = nav.position, revision = nav.revision, copy = nav.copyText(side: .previous)
        nav.setInput("9999"); XCTAssertFalse(nav.go(document: document))
        XCTAssertTrue(nav.reveal()); XCTAssertNil(nav.error); XCTAssertEqual(nav.input, "514")
        XCTAssertEqual(nav.position, saved); XCTAssertNotEqual(nav.revision, revision)
        XCTAssertEqual(nav.position?.pageIndex, 1); XCTAssertEqual(nav.position?.byteOffset, 2049)
        XCTAssertEqual(nav.copyText(side: .previous), copy)
        nav.setInput("515"); XCTAssertTrue(nav.go(document: document)); nav.setInput("1")
        XCTAssertTrue(nav.reveal()); XCTAssertEqual(nav.input, "515"); XCTAssertEqual(nav.position?.byteCount, 0)
        nav.reset(); XCTAssertFalse(nav.reveal())
    }
    func testByteRevealUsesCapturedSlicedContextAndEOFWithoutSourceRead() throws {
        let bytes = Data([99,0,128,255,88])[1..<4]
        var nav = DataByteNavigation()
        XCTAssertFalse(nav.reveal()); nav.setInput("2"); XCTAssertTrue(nav.go(data: bytes))
        let context = nav.context, copy = nav.copyText(side: .current)
        nav.setInput("9999"); XCTAssertFalse(nav.go(data: bytes))
        XCTAssertTrue(nav.reveal()); XCTAssertEqual(nav.input, "2"); XCTAssertNil(nav.error)
        XCTAssertEqual(nav.byteOffset, 1); XCTAssertEqual(nav.context, context)
        XCTAssertEqual(nav.context?.markedHex, "[80]"); XCTAssertEqual(nav.copyText(side: .current), copy)
        nav.setInput("4"); XCTAssertTrue(nav.go(data: bytes)); nav.setInput("1")
        XCTAssertTrue(nav.reveal()); XCTAssertEqual(nav.input, "4"); XCTAssertEqual(nav.context?.markedHex, "[EOF]")
        nav.reset(); XCTAssertFalse(nav.reveal())
    }
    func testRevealLeavesSearchAndDifferenceFrontiersUnchanged() async throws {
        let search = FocusedStringSearch(source: "e\u{301} e\u{301}")
        search.setQuery(.init(value: "e\u{301}")); try await XCTUnwrap(search.find()).value
        let difference = FocusedDataDifference(previous: Data([0,1]), current: Data([9,8]))
        try await XCTUnwrap(difference.find()).value
        let revision = search.matchRevision, payload = search.copyText(side: .previous)
        let diffRevision = difference.revision, details = difference.copyDetails
        var scalar = StringScalarNavigation(), byte = DataByteNavigation()
        let document = try LeafValueDocument(leaf: XCTUnwrap(InspectorLeaf(.string("🙂"))))
        scalar.setInput("1"); XCTAssertTrue(scalar.go(document: document))
        byte.setInput("1"); XCTAssertTrue(byte.go(data: Data([128])))
        XCTAssertTrue(scalar.reveal()); XCTAssertTrue(byte.reveal())
        XCTAssertEqual(search.matchRevision, revision); XCTAssertEqual(search.copyText(side: .previous), payload)
        XCTAssertEqual(difference.revision, diffRevision); XCTAssertEqual(difference.copyDetails, details)
        try await XCTUnwrap(search.advance()).value; XCTAssertEqual(search.match?.byteOffset, 4)
        try await XCTUnwrap(difference.next()).value; XCTAssertEqual(difference.differenceCount, 2)
    }
}
