import Foundation
import XCTest
@testable import EntitlementDiffCore

final class InspectionBoundaryTests: XCTestCase {
    func testUnsignedSuccessfulAPIReturnIsRejected() {
        XCTAssertThrowsError(try SigningMetadataDecoder().decode(signingIdentifier: nil, entitlementDictionary: nil, hasRawEntitlements: false)) {
            XCTAssertEqual($0 as? SigningMetadataError, .unsigned)
        }
    }
    func testMissingDictionaryWithRawBlobIsNotEmpty() {
        XCTAssertThrowsError(try SigningMetadataDecoder().decode(signingIdentifier: "test", entitlementDictionary: nil, hasRawEntitlements: true)) {
            XCTAssertEqual($0 as? SigningMetadataError, .undecodedEntitlements)
        }
    }
    func testAbsentAndEmptyRepresentationsStayDistinct() throws {
        let decoder = SigningMetadataDecoder()
        let absent = try decoder.decode(signingIdentifier: "test", entitlementDictionary: nil, hasRawEntitlements: false)
        let empty = try decoder.decode(signingIdentifier: "test", entitlementDictionary: [:], hasRawEntitlements: true)
        XCTAssertEqual(absent.presence, .notPresent)
        XCTAssertEqual(empty.presence, .dictionaryPresent)
        XCTAssertTrue(absent.entitlements.entries.isEmpty)
        XCTAssertTrue(empty.entitlements.entries.isEmpty)
    }
    func testMalformedIdentifierAndDictionaryAreRejected() {
        for identifier: Any in [NSNumber(value: true), ""] {
            XCTAssertThrowsError(try SigningMetadataDecoder().decode(signingIdentifier: identifier, entitlementDictionary: [:], hasRawEntitlements: false))
        }
        XCTAssertThrowsError(try SigningMetadataDecoder().decode(signingIdentifier: "test", entitlementDictionary: [1, 2], hasRawEntitlements: false))
    }
    func testConventionalBundleWithShellMetacharactersIsReadAsData() throws {
        let fixture = try makeBundle(name: "'-; dollar$ quote\".app")
        defer { try? FileManager.default.removeItem(at: fixture.parent) }
        let result = try AppBundlePreflight.inspect(fixture.app)
        XCTAssertEqual(result.bundleURL, fixture.app)
        XCTAssertEqual(result.executableURL.lastPathComponent, "Main")
    }
    func testRemoteURLRejected() {
        XCTAssertThrowsError(try AppBundlePreflight.inspect(URL(string: "https://example.invalid/a.app")!))
    }
    func testTraversalExecutableNameIsRejected() throws {
        let fixture = try makeBundle(executableName: "../../Outside")
        defer { try? FileManager.default.removeItem(at: fixture.parent) }
        XCTAssertThrowsError(try AppBundlePreflight.inspect(fixture.app))
    }
    func testExecutableSymlinkEscapeIsRejected() throws {
        let fixture = try makeBundle()
        defer { try? FileManager.default.removeItem(at: fixture.parent) }
        let executable = fixture.app.appendingPathComponent("Contents/MacOS/Main")
        let outside = fixture.parent.appendingPathComponent("Outside")
        try Data([0xCF, 0xFA, 0xED, 0xFE]).write(to: outside)
        try FileManager.default.removeItem(at: executable)
        try FileManager.default.createSymbolicLink(at: executable, withDestinationURL: outside)
        XCTAssertThrowsError(try AppBundlePreflight.inspect(fixture.app))
    }
    func testInfoPlistSymlinkEscapeIsRejected() throws {
        let fixture = try makeBundle()
        defer { try? FileManager.default.removeItem(at: fixture.parent) }
        let plist = fixture.app.appendingPathComponent("Contents/Info.plist")
        let outside = fixture.parent.appendingPathComponent("Info.plist")
        try FileManager.default.moveItem(at: plist, to: outside)
        try FileManager.default.createSymbolicLink(at: plist, withDestinationURL: outside)
        XCTAssertThrowsError(try AppBundlePreflight.inspect(fixture.app))
    }
    func testScriptBundleRejectedRatherThanIgnoringArchitecture() throws {
        let fixture = try makeBundle()
        defer { try? FileManager.default.removeItem(at: fixture.parent) }
        try Data("#!/bin/sh\nexit 0\n".utf8).write(to: fixture.app.appendingPathComponent("Contents/MacOS/Main"))
        XCTAssertThrowsError(try AppBundlePreflight.inspect(fixture.app))
    }
    func testOversizedInfoPlistIsRejected() throws {
        let fixture = try makeBundle()
        defer { try? FileManager.default.removeItem(at: fixture.parent) }
        try Data(repeating: 0x20, count: AppBundlePreflight.maximumInfoPlistBytes + 1).write(to: fixture.app.appendingPathComponent("Contents/Info.plist"))
        XCTAssertThrowsError(try AppBundlePreflight.inspect(fixture.app))
    }
    func testMissingAndFakeApplicationPathsAreRejected() throws {
        let parent = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        XCTAssertThrowsError(try AppBundlePreflight.inspect(parent.appendingPathComponent("Missing.app")))
        let fixture = try makeBundle(name: "Wrong.bundle")
        defer { try? FileManager.default.removeItem(at: fixture.parent) }
        XCTAssertThrowsError(try AppBundlePreflight.inspect(fixture.app))
    }
    private func makeBundle(name: String = "Fixture.app", executableName: String = "Main") throws -> (parent: URL, app: URL) {
        let parent = FileManager.default.temporaryDirectory.appendingPathComponent("EntitlementDiffTests-" + UUID().uuidString, isDirectory: true)
        let app = parent.appendingPathComponent(name, isDirectory: true)
        try FileManager.default.createDirectory(at: app.appendingPathComponent("Contents/MacOS"), withIntermediateDirectories: true)
        let plist: [String: Any] = ["CFBundlePackageType": "APPL", "CFBundleExecutable": executableName]
        try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0).write(to: app.appendingPathComponent("Contents/Info.plist"))
        try Data([0xCF, 0xFA, 0xED, 0xFE]).write(to: app.appendingPathComponent("Contents/MacOS/Main"))
        return (parent, app)
    }
}
