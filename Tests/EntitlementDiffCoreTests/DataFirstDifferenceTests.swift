import Foundation
import XCTest
@testable import EntitlementDiffCore

final class DataFirstDifferenceTests: XCTestCase {
    func testNextAdjacentDifferencesAndTerminalEOF() throws {
        var cursor = DataFirstDifference(previous: Data([0, 1, 2]), current: Data([9, 8, 2, 0, 1]))
        XCTAssertFalse(cursor.movePastDifference())
        guard case .difference(let first) = try cursor.step() else { return XCTFail("Missing first") }
        XCTAssertEqual(first.byteOffset, 0); XCTAssertTrue(cursor.movePastDifference())
        guard case .difference(let second) = try cursor.step() else { return XCTFail("Missing adjacent") }
        XCTAssertEqual(second.byteOffset, 1); XCTAssertTrue(cursor.movePastDifference())
        guard case .difference(let end) = try cursor.step() else { return XCTFail("Missing EOF") }
        XCTAssertEqual(end.byteOffset, 3); XCTAssertNil(end.previousByte); XCTAssertEqual(end.currentByte, 0)
        XCTAssertTrue(cursor.movePastDifference()); XCTAssertFalse(cursor.movePastDifference())
        XCTAssertEqual(try cursor.step(), .equal)
        XCTAssertEqual(try cursor.step(), .equal)
    }
    func testNextRetainsCursorAcrossBoundedEqualIntervalAndSlices() throws {
        let a = Data(repeating: 0, count: 20003).dropFirst()
        var b = a; b[b.startIndex] = 0xFF; b[b.index(before: b.endIndex)] = 0x80
        var cursor = DataFirstDifference(previous: a, current: b)
        guard case .difference(let first) = try cursor.step() else { return XCTFail("Missing first") }
        XCTAssertEqual(first.byteOffset, 0); XCTAssertTrue(cursor.movePastDifference())
        XCTAssertEqual(try cursor.step(), .more)
        guard case .difference(let next) = try cursor.step() else { return XCTFail("Missing later") }
        XCTAssertEqual(next.byteOffset, 20001); XCTAssertEqual(next.currentByte, 0x80)
        XCTAssertTrue(cursor.movePastDifference()); XCTAssertEqual(try cursor.step(), .equal)
    }
    func testBudgetLaterPageAndExactBytes() throws {
        var left = Data(repeating: 0xAA, count: 20001), right = left
        left[20000] = 0x7F; right[20000] = 0x80
        var cursor = DataFirstDifference(previous: left, current: right)
        XCTAssertEqual(try cursor.step(byteLimit: Int.max), .more)
        XCTAssertEqual(try cursor.step(), .difference(.init(byteOffset: 20000, previousByte: 0x7F, currentByte: 0x80)))
        guard case .difference(let position) = try cursor.step() else { return XCTFail("Missing difference") }
        XCTAssertEqual(position.pageIndex, 26)
        XCTAssertEqual(position.previousLabel, "7F"); XCTAssertEqual(position.currentLabel, "80")
    }
    func testPrefixEmptyEqualAndSlicedData() throws {
        var prefix = DataFirstDifference(previous: Data(repeating: 0xFF, count: 768), current: Data(repeating: 0xFF, count: 769))
        XCTAssertEqual(try prefix.step(), .difference(.init(byteOffset: 768, previousByte: nil, currentByte: 0xFF)))
        var empty = DataFirstDifference(previous: Data(), current: Data([0]))
        guard case .difference(let end) = try empty.step() else { return XCTFail("Missing EOF") }
        XCTAssertEqual(end.previousLabel, "End of data"); XCTAssertEqual(end.currentLabel, "00")
        var equal = DataFirstDifference(previous: Data(), current: Data())
        XCTAssertEqual(try equal.step(), .equal)
        let a = Data([9, 0, 0xFE, 8]).dropFirst().dropLast()
        let b = Data([7, 0, 0xFF, 6]).dropFirst().dropLast()
        var sliced = DataFirstDifference(previous: a, current: b)
        XCTAssertEqual(try sliced.step(), .difference(.init(byteOffset: 1, previousByte: 0xFE, currentByte: 0xFF)))
    }
    func testEqualityNeedsContinuationAndSmallBudgetRetainsPosition() throws {
        var equal = DataFirstDifference(previous: Data(repeating: 0, count: 16385), current: Data(repeating: 0, count: 16385))
        XCTAssertEqual(try equal.step(), .more); XCTAssertEqual(try equal.step(), .equal)
        var cursor = DataFirstDifference(previous: Data([0, 1, 2]), current: Data([0, 1, 3]))
        XCTAssertEqual(try cursor.step(byteLimit: 2), .more)
        XCTAssertEqual(try cursor.step(byteLimit: 2), .more)
        XCTAssertEqual(try cursor.step(byteLimit: 2), .difference(.init(byteOffset: 2, previousByte: 2, currentByte: 3)))
    }
}
