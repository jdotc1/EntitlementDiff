import Foundation
import XCTest
@testable import EntitlementDiffCore

final class DataDifferenceContextTests: XCTestCase {
    func testMiddleContextKeepsExactBytesAndFixedBounds() throws {
        let source = Data((0..<100).map(UInt8.init))
        let context = try XCTUnwrap(DataDifferenceContext(data: source, byteOffset: 50))
        XCTAssertEqual(context.startByteOffset, 34)
        XCTAssertEqual(context.byteCount, 33)
        XCTAssertEqual(context.beforeHex, "22 23 24 25 26 27 28 29 2A 2B 2C 2D 2E 2F 30 31")
        XCTAssertEqual(context.markedHex, "[32]")
        XCTAssertEqual(context.afterHex, "33 34 35 36 37 38 39 3A 3B 3C 3D 3E 3F 40 41 42")
        XCTAssertEqual(context.rangeLabel, "Bytes 35–67 · brackets mark byte 51")
    }
    func testStartLastEmptyAndPrefixEOFAreDistinctFromZero() throws {
        let data = Data([0, 0x7F, 0x80, 0xFF])
        let first = try XCTUnwrap(DataDifferenceContext(data: data, byteOffset: 0))
        XCTAssertEqual(first.beforeHex, ""); XCTAssertEqual(first.markedHex, "[00]")
        XCTAssertEqual(first.afterHex, "7F 80 FF")
        let last = try XCTUnwrap(DataDifferenceContext(data: data, byteOffset: 3))
        XCTAssertEqual(last.beforeHex, "00 7F 80"); XCTAssertEqual(last.markedHex, "[FF]")
        XCTAssertEqual(last.afterHex, "")
        let end = try XCTUnwrap(DataDifferenceContext(data: data, byteOffset: 4))
        XCTAssertEqual(end.markedHex, "[EOF]"); XCTAssertEqual(end.byteCount, 4)
        XCTAssertEqual(end.rangeLabel, "Bytes 1–4 · EOF at byte 5")
        let empty = try XCTUnwrap(DataDifferenceContext(data: Data(), byteOffset: 0))
        XCTAssertEqual(empty.markedHex, "[EOF]"); XCTAssertEqual(empty.byteCount, 0)
        XCTAssertEqual(empty.beforeHex, ""); XCTAssertEqual(empty.afterHex, "")
        XCTAssertEqual(empty.rangeLabel, "Empty data · EOF at byte 1")
    }
    func testSlicedStorageUsesRelativeOffsetsAndRejectsInvalidPositions() throws {
        let data = Data([9, 0, 0xFE, 0xFF, 8]).dropFirst().dropLast()
        let context = try XCTUnwrap(DataDifferenceContext(data: data, byteOffset: 1))
        XCTAssertEqual(context.beforeHex, "00"); XCTAssertEqual(context.markedHex, "[FE]")
        XCTAssertEqual(context.afterHex, "FF"); XCTAssertEqual(context.startByteOffset, 0)
        let end = try XCTUnwrap(DataDifferenceContext(data: Data(repeating: 0xFF, count: 768), byteOffset: 768))
        XCTAssertEqual(end.byteCount, 16); XCTAssertEqual(end.startByteOffset, 752)
        XCTAssertNil(DataDifferenceContext(data: data, byteOffset: -1))
        XCTAssertNil(DataDifferenceContext(data: data, byteOffset: 4))
        XCTAssertNil(DataDifferenceContext(data: data, byteOffset: Int.max))
    }
}
