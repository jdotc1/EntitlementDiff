import Foundation
import XCTest
@testable import EntitlementDiffCore

final class InspectorLeafTests: XCTestCase {
    func testStringPagesReachSuffixAndPreserveScalarBoundaries() throws {
        let prefix = String(repeating: "e\u{301}", count: 600)
        let original = prefix + "DIFFERENT SUFFIX"
        let leaf = try XCTUnwrap(InspectorLeaf(.string(original)))
        let document = try LeafValueDocument(leaf: leaf)
        XCTAssertEqual(document.pageCount, 3)
        XCTAssertFalse(document.text(onPage: 0).contains("DIFFERENT SUFFIX"))
        XCTAssertTrue(document.text(onPage: 2).contains("DIFFERENT SUFFIX"))
        let reconstructed = (0..<document.pageCount).map {
            String(document.text(onPage: $0).dropFirst().dropLast())
        }.joined()
        XCTAssertEqual(Array(reconstructed.utf8), Array(original.utf8))
        XCTAssertEqual(document.text(onPage: Int.max), document.text(onPage: 2))
        XCTAssertEqual(document.text(onPage: Int.min), document.text(onPage: 0))
    }

    func testDisplayEscapesStayBoundedWhileCopyRetainsOriginal() throws {
        let original = String(repeating: "\u{202E}", count: 700) + "\n\"\\END"
        let leaf = try XCTUnwrap(InspectorLeaf(.string(original)))
        let document = try LeafValueDocument(leaf: leaf)
        XCTAssertEqual(document.pageCount, 2)
        XCTAssertFalse(document.text(onPage: 0).contains("\u{202E}"))
        XCTAssertTrue(document.text(onPage: 1).contains("\\u{000A}"))
        XCTAssertTrue(document.text(onPage: 1).contains("\\\"\\\\END"))
        XCTAssertLessThanOrEqual(document.text(onPage: 0).unicodeScalars.count, 512 * 8 + 2)
        let json = try object(leaf)
        XCTAssertEqual(json["type"] as? String, "string")
        XCTAssertEqual(Array(try XCTUnwrap(json["value"] as? String).utf8), Array(original.utf8))
    }

    func testDataPagesAndCompleteCopyPreserveSlicedBytes() throws {
        let storage = Data((0..<1_800).map { UInt8($0 % 251) })
        let data = storage[11..<1_655]
        let leaf = try XCTUnwrap(InspectorLeaf(.data(data)))
        let document = try LeafValueDocument(leaf: leaf)
        XCTAssertEqual(document.pageCount, 3)
        let joined = (0..<document.pageCount).map { document.text(onPage: $0) }.joined()
        XCTAssertEqual(joined, data.base64EncodedString())
        XCTAssertLessThanOrEqual(document.text(onPage: 0).count, 1_024)
        let json = try object(leaf)
        XCTAssertEqual(json["type"] as? String, "data-base64")
        XCTAssertEqual(json["value"] as? String, data.base64EncodedString())
    }

    func testTypedScalarsAndEmptyLeavesDoNotBecomeContainersOrAbsent() throws {
        let cases: [(EntitlementValue, String)] = [
            (.boolean(false), "boolean"), (.integer(Int64.min), "integer"),
            (.unsignedInteger(UInt64.max), "integer"), (.real(-0.0), "real"),
            (.date(Date(timeIntervalSinceReferenceDate: 123.125)), "date-reference-seconds"),
            (.string(""), "string"), (.data(Data()), "data-base64")
        ]
        for (value, tag) in cases {
            let leaf = try XCTUnwrap(InspectorLeaf(value))
            XCTAssertEqual(try object(leaf)["type"] as? String, tag)
            XCTAssertEqual(try LeafValueDocument(leaf: leaf).pageCount, 1)
        }
        XCTAssertEqual(try object(XCTUnwrap(InspectorLeaf(.integer(Int64.min))))["value"] as? String, String(Int64.min))
        XCTAssertEqual(try object(XCTUnwrap(InspectorLeaf(.unsignedInteger(UInt64.max))))["value"] as? String, String(UInt64.max))
        // Decode the tagged real as Double. JSONSerialization can infer integer 0
        // for lexical -0 and discard its sign before this assertion sees it.
        struct TaggedReal: Decodable { let type: String; let value: Double }
        let realJSON = try XCTUnwrap(InspectorLeaf(.real(-0.0))).jsonData()
        let real = try JSONDecoder().decode(TaggedReal.self, from: realJSON)
        XCTAssertEqual(real.type, "real")
        XCTAssertEqual(real.value.sign, .minus, String(decoding: realJSON, as: UTF8.self))
        XCTAssertNil(InspectorLeaf(nil))
        XCTAssertNil(InspectorLeaf(.array([])))
        XCTAssertNil(InspectorLeaf(.dictionary(.init())))
        XCTAssertThrowsError(try InspectorLeaf(.real(.nan))?.jsonData())
    }

    func testLeafDiscoveryKeepsByteDistinctKeysAndMixedContainerContext() throws {
        let old = try EntitlementDictionary(entries: [
            .init(key: "é", value: .string("composed")),
            .init(key: "e\u{301}", value: .integer(7))
        ])
        let new = try EntitlementDictionary(entries: [
            .init(key: "é", value: .array([.boolean(true)])),
            .init(key: "e\u{301}", value: .integer(8))
        ])
        let rows = ValueInspector(previous: .dictionary(old), current: .dictionary(new), expanded: ["root"]).rows
        XCTAssertFalse(rows[0].hasLeafValue)
        XCTAssertTrue(rows[1].hasLeafValue)
        XCTAssertTrue(rows[2].hasLeafValue)
        XCTAssertNotEqual(rows[1].id, rows[2].id)
        XCTAssertEqual(InspectorLeaf(rows[1].previous)?.value, .integer(7))
        XCTAssertEqual(InspectorLeaf(rows[2].previous)?.value, .string("composed"))
        XCTAssertNil(InspectorLeaf(rows[2].current))
    }

    private func object(_ leaf: InspectorLeaf) throws -> [String: Any] {
        try XCTUnwrap(JSONSerialization.jsonObject(with: leaf.jsonData()) as? [String: Any])
    }
}
