import Foundation
import XCTest
import EntitlementDiffCore
@testable import EntitlementDiffSecurity

@MainActor
final class IdentityNativeTests: XCTestCase {
    func testNativeIdentityRefreshesAndMalformedOptionalFieldsDoNotFailRead() async throws {
        let fixture = try NativeFixture()
        let plistURL = fixture.app.appendingPathComponent("Contents/Info.plist")
        var info = try XCTUnwrap(PropertyListSerialization.propertyList(from: Data(contentsOf: plistURL), format: nil) as? [String:Any])
        info["CFBundleShortVersionString"] = "1.0"; info["CFBundleVersion"] = "001"
        try PropertyListSerialization.data(fromPropertyList: info, format: .xml, options: 0).write(to: plistURL)
        try fixture.build(architecture: .hostDefault, entitlements: ["flag":true])
        let reader = SecurityEntitlementReader()
        let first = try await reader.read(at: fixture.app, architecture: .hostDefault)
        XCTAssertEqual(first.identity?.version, "1.0"); XCTAssertEqual(first.identity?.build, "001")
        info["CFBundleShortVersionString"] = "2.0"; info["CFBundleVersion"] = 99
        try PropertyListSerialization.data(fromPropertyList: info, format: .xml, options: 0).write(to: plistURL)
        let second = try await reader.read(at: fixture.app, architecture: .hostDefault)
        XCTAssertEqual(second.identity?.version, "2.0"); XCTAssertNil(second.identity?.build)
        XCTAssertEqual(second.identity?.bundleIdentifier, NativeFixture.identifier)
        XCTAssertEqual(second.entitlements["flag"], .boolean(true))
        XCTAssertFalse(FileManager.default.fileExists(atPath: fixture.executionMarker.path))
    }
}
