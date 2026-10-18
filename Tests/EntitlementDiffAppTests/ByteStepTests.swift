import Foundation
import XCTest
import EntitlementDiffCore
@testable import EntitlementDiffApp

@MainActor
final class ByteStepTests: XCTestCase {
    func testOriginalSlicedBytesContextAndCopyFollowSteps() throws {
        let data=Data([99,0,128,255,88])[1..<4]
        var nav=DataByteNavigation();nav.setInput("1");XCTAssertTrue(nav.go(data:data))
        XCTAssertTrue(nav.step(.next,data:data));XCTAssertEqual(nav.context?.markedHex,"[80]")
        XCTAssertEqual(nav.context?.beforeHex,"00");XCTAssertEqual(nav.context?.afterHex,"FF")
        XCTAssertTrue(try XCTUnwrap(nav.copyText(side:.previous)).contains("Byte position: 2 (1-based)"))
        XCTAssertTrue(nav.step(.next,data:data));XCTAssertEqual(nav.context?.markedHex,"[FF]")
        XCTAssertTrue(nav.step(.previous,data:data));XCTAssertEqual(nav.context?.markedHex,"[80]")
    }
    func testFirstEOFEmptyAndNoWrap() {
        let data=Data([128]);var nav=DataByteNavigation()
        XCTAssertFalse(nav.canStep(.next,dataCount:1));XCTAssertFalse(nav.step(.next,data:data))
        nav.setInput("1");XCTAssertTrue(nav.go(data:data));let first=nav.context
        XCTAssertFalse(nav.step(.previous,data:data));XCTAssertEqual(nav.context,first)
        XCTAssertTrue(nav.step(.next,data:data));XCTAssertEqual(nav.context?.markedHex,"[EOF]");XCTAssertEqual(nav.input,"2")
        let eof=nav.context;XCTAssertFalse(nav.step(.next,data:data));XCTAssertEqual(nav.context,eof)
        XCTAssertTrue(nav.step(.previous,data:data));XCTAssertEqual(nav.context?.markedHex,"[80]")
        nav.setInput("1");XCTAssertTrue(nav.go(data:Data()))
        XCTAssertFalse(nav.canStep(.previous,dataCount:0));XCTAssertFalse(nav.canStep(.next,dataCount:0))
    }
    func testBoundaryPendingInputBoundedContextAndIndependentPanes() throws {
        let data=Data((0..<100000).map { UInt8($0 % 256) });var left=DataByteNavigation(),right=DataByteNavigation()
        left.setInput("768");XCTAssertTrue(left.go(data:data));right.setInput("2");XCTAssertTrue(right.go(data:data));let rightContext=right.context
        XCTAssertEqual(try XCTUnwrap(left.byteOffset)/LeafValueDocument.dataBytesPerPage,0)
        left.setInput("100002");XCTAssertFalse(left.go(data:data));XCTAssertNotNil(left.error)
        XCTAssertTrue(left.step(.next,data:data));XCTAssertEqual(left.input,"769");XCTAssertNil(left.error)
        XCTAssertEqual(try XCTUnwrap(left.byteOffset)/LeafValueDocument.dataBytesPerPage,1);XCTAssertEqual(left.context?.markedHex,"[00]");XCTAssertEqual(left.context?.byteCount,33)
        left.setInput("1");XCTAssertTrue(left.step(.previous,data:data));XCTAssertEqual(left.input,"768");XCTAssertEqual(left.context?.markedHex,"[FF]")
        XCTAssertEqual(right.context,rightContext);left.reset();XCTAssertFalse(left.canStep(.next,dataCount:data.count));XCTAssertNil(left.copyText(side:.previous))
    }
    func testSteppingLeavesDifferenceSelectionAndFrontierUnchanged() async throws {
        let difference=FocusedDataDifference(previous:Data([0,1,2]),current:Data([9,8,7]))
        try await XCTUnwrap(difference.find()).value
        let position=difference.position,revision=difference.revision,copy=difference.copyDetails
        var nav=DataByteNavigation();nav.setInput("2");XCTAssertTrue(nav.go(data:Data([0,1,2])))
        XCTAssertTrue(nav.step(.next,data:Data([0,1,2])));XCTAssertTrue(nav.step(.previous,data:Data([0,1,2])))
        XCTAssertEqual(difference.position,position);XCTAssertEqual(difference.revision,revision);XCTAssertEqual(difference.copyDetails,copy)
        try await XCTUnwrap(difference.next()).value;XCTAssertEqual(difference.differenceCount,2);XCTAssertEqual(difference.position?.byteOffset,1)
    }
}
