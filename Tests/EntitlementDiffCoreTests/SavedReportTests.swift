import Foundation
import XCTest
@testable import EntitlementDiffCore

final class SavedReportTests: XCTestCase {
    private func report(_ values: EntitlementDictionary = .init()) throws -> Data {
        let a = EntitlementSnapshot(sourceName: "Old.app", signingIdentifier: "org.example", architecture: .arm64, entitlements: values)
        let b = EntitlementSnapshot(sourceName: "New.app", signingIdentifier: "org.example", architecture: .arm64, entitlements: values)
        return try ComparisonReport(previous: a, current: b).jsonData()
    }
    private func mutate(_ data: Data, _ change: (inout [String: Any]) -> Void) throws -> Data {
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        change(&object); return try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])
    }
    func testTypedValuesUnicodeAndSchemaRoundTrip() throws {
        let values = try EntitlementDictionary(entries: [
            .init(key: "é", value: .unsignedInteger(UInt64.max)),
            .init(key: "e\u{301}", value: .integer(Int64.min)),
            .init(key: "array", value: .array([.boolean(false), .real(-0.0), .string("suffix\n"), .data(Data([0,255])), .date(Date(timeIntervalSinceReferenceDate: 1.25)), .dictionary(.init(["unknown": .integer(9)]))]))
        ])
        let data = try report(values), saved = try SavedReport.parse(data)
        XCTAssertEqual(saved.previous.entitlements, values)
        XCTAssertTrue(saved.previous.isSavedBaseline)
        XCTAssertNil(saved.previous.identity)
        let output = try ComparisonReport(previous: saved.previous, current: saved.current).jsonData()
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: output) as? [String: Any])
        XCTAssertEqual(json["schemaVersion"] as? Int, 1)
        let snapshot = try XCTUnwrap(json["previous"] as? [String: Any])
        XCTAssertEqual(Set(snapshot.keys), ["sourceName","signingIdentifier","architecture","presence","origin","entitlements"])
        XCTAssertFalse(String(decoding: output, as: UTF8.self).contains("isSavedBaseline"))
    }
    func testUntrustedDerivedClaimsAreRecomputed() throws {
        let data = try mutate(report(.init(["key": .integer(1)]))) { $0["unchangedCount"] = 999; $0["changes"] = []; $0["notices"] = ["trusted"] }
        let saved = try SavedReport.parse(data)
        let recomputed = try ComparisonReport(previous: saved.previous, current: saved.current)
        XCTAssertEqual(recomputed.unchangedCount, 1)
        XCTAssertFalse(recomputed.notices.contains("trusted"))
        XCTAssertTrue(recomputed.notices.contains { $0.contains("saved-report") })
    }
    func testRejectsVersionDuplicatesMalformedTypesAndSnapshotInvariants() throws {
        let data = try report()
        for field in ["schemaVersion", "tool", "signatureValidation"] {
            XCTAssertThrowsError(try SavedReport.parse(mutate(data) { $0[field] = "unsupported" }))
        }
        let duplicate = String(decoding: data, as: UTF8.self).replacingOccurrences(of: "\"schemaVersion\" : 1", with: "\"schemaVersion\" : 1, \"schemaVersion\" : 1")
        XCTAssertNotEqual(duplicate, String(decoding: data, as: UTF8.self))
        XCTAssertThrowsError(try SavedReport.parse(Data(duplicate.utf8)))
        for entries: [[String: Any]] in [
            [["key":"x","value":["type":"integer","value":"18446744073709551616"]]],
            [["key":"x","value":["type":"boolean","value":1]]],
            [["key":"x","value":["type":"string","value":"a"]],["key":"x","value":["type":"string","value":"b"]]]
        ] {
            XCTAssertThrowsError(try SavedReport.parse(mutate(data) { root in
                var old = root["previous"] as! [String: Any]; old["entitlements"] = entries; root["previous"] = old
            }))
        }
        for replacement in [["sourceName":"/private/Old.app"], ["signingIdentifier":""], ["architecture":"x86_64"]] {
            XCTAssertThrowsError(try SavedReport.parse(mutate(data) { root in
                var old = root["previous"] as! [String: Any]; for (k,v) in replacement { old[k] = v }; root["previous"] = old
            }))
        }
    }
    func testParsingBudgetsAndFileReadAreBounded() throws {
        XCTAssertThrowsError(try SavedReport.parse(Data(repeating: 32, count: SavedReport.maximumBytes + 1)))
        XCTAssertThrowsError(try SavedReport.parse(Data((String(repeating: "[", count: 98) + "0" + String(repeating: "]", count: 98)).utf8)))
        XCTAssertThrowsError(try SavedReport.parse(Data(("\"" + String(repeating: "x", count: 1_024 * 1_024 + 1) + "\"").utf8)))
        XCTAssertThrowsError(try SavedReport.parse(Data(("[" + String(repeating: "0,", count: 100_001) + "0]").utf8)))
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: url) }
        try report().write(to: url)
        XCTAssertEqual(try SavedReport.read(at: url).current.sourceName, "New.app")
    }
}
