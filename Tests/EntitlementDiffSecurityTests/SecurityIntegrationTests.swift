import Foundation
import XCTest
import EntitlementDiffCore
@testable import EntitlementDiffSecurity

/// These tests require a macOS SDK and command-line developer tools. Fixtures
/// are compiled/signed in a temporary directory and are NEVER executed.
@MainActor
final class SecurityIntegrationTests: XCTestCase {
    func testMagicPrefixAloneDoesNotEstablishMachOArchitecture() async throws {
        let fixture = try NativeFixture()
        // Portable preflight deliberately recognizes a prefix only; native
        // architecture discovery must still reject this truncated impostor.
        try Data([0xCF, 0xFA, 0xED, 0xFE]).write(to: fixture.executable)
        do {
            _ = try await SecurityEntitlementReader().read(at: fixture.app, architecture: .arm64)
            XCTFail("A four-byte magic prefix cannot satisfy a native architecture request.")
        } catch {
            XCTAssertEqual(error as? BundleInputError, .machORequired)
        }
    }

    func testAdHocSignedBundleExtractsExactBooleanAndInteger() async throws {
        let fixture = try NativeFixture()
        try fixture.build(architecture: .hostDefault, entitlements: ["test.boolean": true, "test.integer": 1])
        let snapshot = try await SecurityEntitlementReader().read(at: fixture.app, architecture: .hostDefault)
        XCTAssertEqual(snapshot.entitlements["test.boolean"], .boolean(true))
        XCTAssertEqual(snapshot.entitlements["test.integer"], .integer(1))
        XCTAssertEqual(snapshot.architecture, .hostDefault)
        XCTAssertEqual(snapshot.signingIdentifier, NativeFixture.identifier)
    }

    func testUnsignedBundleIsNotAnEmptyDictionary() async throws {
        let fixture = try NativeFixture()
        try fixture.build(architecture: .hostDefault, signed: false)
        do {
            _ = try await SecurityEntitlementReader().read(at: fixture.app, architecture: .hostDefault)
            XCTFail("Unsigned input must be rejected, not converted to empty entitlements.")
        } catch {
            XCTAssertEqual(error as? SigningMetadataError, .unsigned)
        }
    }

    func testSignedBundleWithoutEntitlementsIsReadable() async throws {
        let fixture = try NativeFixture()
        try fixture.build(architecture: .hostDefault)
        let snapshot = try await SecurityEntitlementReader().read(at: fixture.app, architecture: .hostDefault)
        XCTAssertTrue(snapshot.entitlements.entries.isEmpty)
        XCTAssertFalse(snapshot.signingIdentifier.isEmpty)
    }

    func testMissingArchitectureDoesNotFallBack() async throws {
        let fixture = try NativeFixture()
        try fixture.build(architecture: .arm64, entitlements: ["test.architecture": "arm64"])
        do {
            _ = try await SecurityEntitlementReader().read(at: fixture.app, architecture: .x86_64)
            XCTFail("A thin arm64 binary must not satisfy an x86_64 request.")
        } catch {
            XCTAssertTrue(error is NativeInspectionError)
        }
    }

    func testUniversalSlicesAreSelectedExplicitly() async throws {
        let fixture = try NativeFixture()
        try fixture.buildUniversalWithDistinctEntitlements()
        let reader = SecurityEntitlementReader()
        let arm = try await reader.read(at: fixture.app, architecture: .arm64)
        let intel = try await reader.read(at: fixture.app, architecture: .x86_64)
        XCTAssertEqual(arm.entitlements["test.slice"], .string("arm64"))
        XCTAssertEqual(intel.entitlements["test.slice"], .string("x86_64"))
    }

    func testReadingDoesNotExecuteOrModifyFixture() async throws {
        let fixture = try NativeFixture()
        try fixture.build(architecture: .hostDefault, entitlements: ["test.read-only": true])
        let beforeExecutable = try Data(contentsOf: fixture.executable)
        let beforeInfo = try Data(contentsOf: fixture.app.appendingPathComponent("Contents/Info.plist"))
        _ = try await SecurityEntitlementReader().read(at: fixture.app, architecture: .hostDefault)
        XCTAssertEqual(try Data(contentsOf: fixture.executable), beforeExecutable)
        XCTAssertEqual(try Data(contentsOf: fixture.app.appendingPathComponent("Contents/Info.plist")), beforeInfo)
        XCTAssertFalse(FileManager.default.fileExists(atPath: fixture.executionMarker.path))
    }

    func testDamagedResourceDoesNotTurnReportIntoTrustVerdict() async throws {
        let fixture = try NativeFixture()
        try fixture.build(architecture: .hostDefault, entitlements: ["test.flag": true])
        try Data("modified after signing".utf8).write(to: fixture.resource)
        let snapshot = try await SecurityEntitlementReader().read(at: fixture.app, architecture: .hostDefault)
        let report = try ComparisonReport(previous: snapshot, current: snapshot)
        XCTAssertEqual(report.signatureValidation, "notPerformed")
        XCTAssertEqual(report.gatekeeperAssessment, "notPerformed")
    }
}
