import Foundation
import XCTest
@testable import EntitlementDiffCore

final class IdentityMetadataTests: XCTestCase {
    func testOptionalFieldsRejectMalformedAndOversizedWithoutCoercion() {
        let valid = AppIdentity(infoPlist: ["CFBundleIdentifier": "org.example.app", "CFBundleShortVersionString": "1.2", "CFBundleVersion": "007"])
        XCTAssertEqual(valid.version, "1.2")
        XCTAssertEqual(valid.build, "007")
        XCTAssertEqual(valid.bundleIdentifier, "org.example.app")
        let invalid = AppIdentity(infoPlist: ["CFBundleIdentifier": true, "CFBundleShortVersionString": 42, "CFBundleVersion": String(repeating: "é", count: 129)])
        XCTAssertNil(invalid.bundleIdentifier); XCTAssertNil(invalid.version); XCTAssertNil(invalid.build)
        XCTAssertEqual(AppIdentity(infoPlist: ["CFBundleVersion": String(repeating: "é", count: 128)]).build?.utf8.count, 256)
        XCTAssertNil(AppIdentity(infoPlist: ["CFBundleVersion": " \n\t "]).build)
        XCTAssertNil(AppIdentity(infoPlist: [:]).version)
    }

    func testPreflightCapturesIdentityFromValidatedBoundedPlist() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let app = root.appendingPathComponent("Same.app")
        let binary = app.appendingPathComponent("Contents/MacOS/Main")
        try FileManager.default.createDirectory(at: binary.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data([0xCF,0xFA,0xED,0xFE]).write(to: binary)
        let info: [String: Any] = ["CFBundleExecutable":"Main", "CFBundlePackageType":"APPL", "CFBundleIdentifier":"org.example.bundle", "CFBundleShortVersionString":"2.0", "CFBundleVersion":false]
        try PropertyListSerialization.data(fromPropertyList: info, format: .xml, options: 0).write(to: app.appendingPathComponent("Contents/Info.plist"))
        let location = try AppBundlePreflight.inspect(app)
        XCTAssertEqual(location.identity.bundleIdentifier, "org.example.bundle")
        XCTAssertEqual(location.identity.version, "2.0")
        XCTAssertNil(location.identity.build)
    }

    func testUIIdentityDoesNotChangeReportBytesOrSnapshotSchema() throws {
        func snapshot(_ identity: AppIdentity?) -> EntitlementSnapshot {
            .init(sourceName: "Same.app", signingIdentifier: "org.example.signing", architecture: .arm64,
                  entitlements: .init(["flag": .boolean(true)]), identity: identity)
        }
        let baseline = snapshot(nil)
        let withIdentity = snapshot(.init(infoPlist: ["CFBundleIdentifier":"/private/UI-ONLY", "CFBundleShortVersionString":"UI-VERSION", "CFBundleVersion":"UI-BUILD"]))
        let a = try ComparisonReport(previous: baseline, current: baseline)
        let b = try ComparisonReport(previous: withIdentity, current: withIdentity)
        XCTAssertEqual(try a.jsonData(), try b.jsonData())
        XCTAssertEqual(a.text(), b.text())
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: b.jsonData()) as? [String:Any])
        XCTAssertEqual(json["schemaVersion"] as? Int, 1)
        let encoded = try XCTUnwrap(json["previous"] as? [String:Any])
        XCTAssertEqual(Set(encoded.keys), Set(["sourceName", "signingIdentifier", "architecture", "presence", "origin", "entitlements"]))
    }
}
