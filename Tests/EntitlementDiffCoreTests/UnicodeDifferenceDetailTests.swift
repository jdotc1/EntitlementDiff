import XCTest
@testable import EntitlementDiffCore

final class UnicodeDifferenceDetailTests: XCTestCase {
    func testCapturedComposedDecomposedAndFourByteDetails() throws {
        var cursor = StringFirstDifference(previous: String(repeating: "x", count: 16385) + "é", current: String(repeating: "x", count: 16385) + "e\u{301}")
        XCTAssertEqual(try cursor.step(), .more)
        guard case .difference(let position) = try cursor.step() else { return XCTFail("Missing difference") }
        XCTAssertEqual(position.previousScalar?.value, 0xE9)
        XCTAssertEqual(position.currentScalar?.value, 0x65)
        XCTAssertEqual(position.previousDetail.scalarLabel, "U+00E9 · \\u{00E9}")
        XCTAssertEqual(position.previousDetail.utf8Bytes, "C3 A9")
        XCTAssertEqual(position.currentDetail.utf8Bytes, "65")
        let emoji = StringScalarDetail(scalar: "🙂")
        XCTAssertEqual(emoji.scalarLabel, "U+1F642 · \\u{1F642}")
        XCTAssertEqual(emoji.utf8Bytes, "F0 9F 99 82")
    }
    func testInvisibleScalarsAndEndHaveUnambiguousBoundedLabels() throws {
        for (scalar, label, bytes) in [("\u{0000}", "U+0000 · \\u{0000}", "00"), (" ", "U+0020 · \\u{0020}", "20"), ("\u{200B}", "U+200B · \\u{200B}", "E2 80 8B"), ("\u{301}", "U+0301 · \\u{0301}", "CC 81")] as [(Unicode.Scalar, String, String)] {
            let detail = StringScalarDetail(scalar: scalar)
            XCTAssertEqual(detail.scalarLabel, label)
            XCTAssertEqual(detail.utf8Bytes, bytes)
            XCTAssertLessThanOrEqual(detail.scalarLabel.utf8.count, 32)
            XCTAssertLessThanOrEqual(try XCTUnwrap(detail.utf8Bytes).count, 11)
        }
        var cursor = StringFirstDifference(previous: "🙂", current: "🙂x")
        guard case .difference(let position) = try cursor.step() else { return XCTFail("Missing prefix difference") }
        XCTAssertNil(position.previousScalar)
        XCTAssertEqual(position.previousDetail.scalarLabel, "End of string")
        XCTAssertNil(position.previousDetail.utf8Bytes)
        XCTAssertEqual(position.previousByteCount, 0)
        XCTAssertEqual(position.currentDetail.scalarLabel, "U+0078 · \\u{0078}")
    }
}
