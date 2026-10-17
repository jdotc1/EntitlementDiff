import Foundation
import XCTest
import EntitlementDiffCore
@testable import EntitlementDiffApp

@MainActor
final class DataByteNavigationTests: XCTestCase {
    func testOriginalBytesSlicedDataAndEOF() throws {
        let data = Data([99,0,128,255,88])[1..<4]
        XCTAssertNotEqual(data.startIndex, 0)
        var nav = DataByteNavigation()
        for (input, expected) in [("1","[00]"),("2","[80]"),("3","[FF]"),("4","[EOF]")] {
            nav.setInput(input); XCTAssertTrue(nav.go(data: data))
            XCTAssertEqual(nav.context?.markedHex, expected)
        }
        XCTAssertEqual(nav.context?.beforeHex, "00 80 FF")
        nav.setInput("1"); XCTAssertTrue(nav.go(data: Data()))
        XCTAssertEqual(nav.context?.rangeLabel, "Empty data · EOF at byte 1")
    }
    func testStrictBoundedInputInvalidNonmutationAndReset() {
        var nav = DataByteNavigation(); nav.setInput("2"); XCTAssertTrue(nav.go(data: Data([0,1,2])))
        let saved = nav.context
        for text in ["", "0", "5", "-1", "+1", " 1", "1 ", "1.0", "١", "１", "18446744073709551615", String(repeating:"9",count:10000)] {
            nav.setInput(text); XCTAssertLessThanOrEqual(nav.input.utf8.count,21)
            XCTAssertFalse(nav.go(data: Data([0,1,2]))); XCTAssertNotNil(nav.error)
            XCTAssertEqual(nav.context,saved); XCTAssertEqual(nav.byteOffset,1)
        }
        nav.setInput("0003"); XCTAssertTrue(nav.go(data:Data([0,1,2]))); XCTAssertNil(nav.error)
        nav.reset(); XCTAssertNil(nav.context); XCTAssertNil(nav.byteOffset); XCTAssertNil(nav.error); XCTAssertEqual(nav.input,"1")
    }
    func testLargeValueOnlyFixedContextAndIndependentPanes() {
        let data = Data(repeating:255,count:100000)
        var previous = DataByteNavigation(), current = DataByteNavigation()
        previous.setInput("50000"); XCTAssertTrue(previous.go(data:data))
        XCTAssertEqual(previous.context?.byteCount,33); XCTAssertEqual(previous.context?.startByteOffset,49983)
        XCTAssertNil(current.context)
        current.setInput("100001"); XCTAssertTrue(current.go(data:data))
        XCTAssertEqual(current.context?.byteCount,16); XCTAssertEqual(current.context?.markedHex,"[EOF]")
        XCTAssertEqual(previous.byteOffset,49999)
    }
    func testManualContextDoesNotChangeDifferenceSelectionOrCopy() async throws {
        let difference = FocusedDataDifference(previous:Data([0,1,2]),current:Data([9,8,7]))
        try await XCTUnwrap(difference.find()).value
        let saved = difference.position, revision = difference.revision, copy = difference.copyDetails
        var nav = DataByteNavigation();nav.setInput("3");XCTAssertTrue(nav.go(data:Data([0,1,2])))
        XCTAssertEqual(difference.position,saved); XCTAssertEqual(difference.revision,revision); XCTAssertEqual(difference.copyDetails,copy)
        difference.reveal(); nav.reset(); XCTAssertNil(nav.context)
        try await XCTUnwrap(difference.next()).value; XCTAssertEqual(difference.differenceCount,2)
    }
}
