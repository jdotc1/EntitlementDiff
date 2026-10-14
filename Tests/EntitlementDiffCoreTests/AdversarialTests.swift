import Foundation
import XCTest
@testable import EntitlementDiffCore

final class AdversarialTests: XCTestCase {
    func testPreviewBoundsUnicodeScalarsNotPotentiallyUnboundedGraphemes() {
        let value = EntitlementValue.string("a" + String(repeating: "\u{0301}", count: 10_000))
        let result = value.preview(maxCharacters: 8)
        let expected = String(String.UnicodeScalarView(value.rendered.unicodeScalars.prefix(8))) + "…"
        XCTAssertEqual(result, expected)
        XCTAssertEqual(result.unicodeScalars.count, 9)
    }

    func testPreviewMatchesRenderedScalarPrefixAtEveryBoundary() {
        let values: [EntitlementValue] = [
            .boolean(false), .integer(.min), .unsignedInteger(.max), .real(-0.0),
            .date(Date(timeIntervalSinceReferenceDate: 12.5)),
            .string("a\n\"\\\u{202E}é👩‍💻"),
            .data(Data()), .data(Data(0...90)),
            .array([.integer(1), .string("longer"), .array([])]),
            .dictionary(.init(["z": .boolean(true), "a\t": .array([.string("e\u{0301}"), .real(3)])]))
        ]
        for value in values {
            let full = value.rendered
            for cap in 1...(full.unicodeScalars.count + 2) {
                let prefix = String(String.UnicodeScalarView(full.unicodeScalars.prefix(cap)))
                let expected = prefix + (full.unicodeScalars.count > cap ? "…" : "")
                XCTAssertEqual(value.preview(maxCharacters: cap), expected, "type=\(value.typeName), cap=\(cap)")
            }
            XCTAssertEqual(value.preview(maxCharacters: 0), "…")
            XCTAssertEqual(value.preview(maxCharacters: -1), "…")
        }
    }

    func testLargeCollectionPreviewHasFixedOutputBudget() {
        let value = EntitlementValue.array(Array(repeating: .string("payload"), count: 100_000))
        XCTAssertEqual(value.preview(maxCharacters: 17), "[\"payload\", \"payl…")
        XCTAssertEqual(EntitlementValue.data(Data(repeating: 255, count: 8_388_608)).preview(maxCharacters: 16),
                       "data(base64: ///…")
    }

    func testSigningIdentifierHasIndependentUTF8ByteBudget() throws {
        let decoder = SigningMetadataDecoder()
        let accepted = String(repeating: "é", count: 2_048)
        XCTAssertEqual(try decoder.decode(signingIdentifier: accepted, entitlementDictionary: nil,
                                         hasRawEntitlements: false).signingIdentifier, accepted)
        XCTAssertThrowsError(try decoder.decode(signingIdentifier: accepted + "a", entitlementDictionary: nil,
                                               hasRawEntitlements: false))
    }

    func testDecimalNumberIsRejectedInsteadOfRoundedToBinaryDouble() {
        XCTAssertThrowsError(try FoundationEntitlementDecoder().decode([
            "decimal": NSDecimalNumber(string: "9007199254740993.1")
        ]))
    }

    func testSeededComparisonsAgreeWithIndependentReferenceAndReverseDirection() throws {
        var random = Generator()
        for _ in 0..<500 {
            var previous: [String: EntitlementValue] = [:]
            var current: [String: EntitlementValue] = [:]
            for index in 0..<40 {
                let key = String(format: "key-%02d", index)
                if random.next() % 3 != 0 { previous[key] = random.value() }
                if random.next() % 3 != 0 { current[key] = random.value() }
            }
            let result = EntitlementComparison(previous: .init(previous), current: .init(current))
            let reverse = EntitlementComparison(previous: .init(current), current: .init(previous))
            let keys = Set(previous.keys).union(current.keys).sorted()
            XCTAssertEqual(result.rows.map(\.key), keys)
            for (index, key) in keys.enumerated() {
                let row = result.rows[index]
                let expected: ChangeKind = previous[key] == nil ? .added : current[key] == nil ? .removed
                    : previous[key] == current[key] ? .unchanged : .changed
                XCTAssertEqual(row.kind, expected)
                XCTAssertEqual(row.previous, reverse.rows[index].current)
                XCTAssertEqual(row.current, reverse.rows[index].previous)
                XCTAssertEqual(reverse.rows[index].kind, expected == .added ? .removed : expected == .removed ? .added : expected)
            }
        }
    }
}

private struct Generator {
    private var state: UInt64 = 0xE17D1FF
    mutating func next() -> UInt64 {
        state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
        return state
    }
    mutating func value() -> EntitlementValue {
        switch next() % 5 {
        case 0: return .boolean(next() % 2 == 0)
        case 1: return .integer(Int64(next() % 20))
        case 2: return .string("value-\(next() % 9)")
        case 3: return .array([.integer(Int64(next() % 7)), .boolean(true)])
        default: return .dictionary(.init(["nested": .unsignedInteger(next())]))
        }
    }
}
