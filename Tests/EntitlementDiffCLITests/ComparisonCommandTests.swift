import Foundation
import XCTest
import EntitlementDiffCore
@testable import EntitlementDiffCLIKit

final class ComparisonCommandTests: XCTestCase, @unchecked Sendable {
    private let args = ["--previous", "Before.app", "--current", "After.app", "--architecture", "arm64"]
    func testStrictArgumentsAndExplicitArchitecture() throws {
        for a in [[], Array(args.dropLast(2)), args + ["--previous", "Other.app"], args + ["--unknown", "x"], Array(args.dropLast()) + ["arm64e"]] {
            XCTAssertThrowsError(try ComparisonCommand(arguments: a))
        }
        XCTAssertEqual(try ComparisonCommand(arguments: args).architecture, .arm64)
    }
    func testExactSchemaAndDifferenceStatus() async throws {
        let pair = ExampleSnapshots.pair(architecture: .arm64)
        let command = try ComparisonCommand(arguments: args)
        let result = try await command.run(reader: PairReader(before: pair.0, after: pair.1))
        XCTAssertEqual(result.exitStatus, 1)
        XCTAssertEqual(result.standardOutput, try ComparisonReport(previous: pair.0, current: pair.1).jsonData())
        let equal = try await command.run(reader: PairReader(before: pair.0, after: pair.0))
        XCTAssertEqual(equal.exitStatus, 0)
        XCTAssertFalse(String(decoding: result.standardOutput, as: UTF8.self).contains(FileManager.default.currentDirectoryPath))
    }
    func testOutputExclusivityAndInputProtection() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let pair = ExampleSnapshots.pair(architecture: .arm64), reader = PairReader(before: pair.0, after: pair.1)
        let output = root.appendingPathComponent("report.json")
        let command = try ComparisonCommand(arguments: args + ["--output", output.path], directory: root)
        let result = try await command.run(reader: reader); XCTAssertTrue(result.standardOutput.isEmpty)
        let saved = try Data(contentsOf: output)
        do { _ = try await command.run(reader: reader); XCTFail("overwrite accepted") } catch {}
        XCTAssertEqual(try Data(contentsOf: output), saved)
        let bundle = root.appendingPathComponent("Before.app")
        try FileManager.default.createDirectory(at: bundle, withIntermediateDirectories: true)
        let protected = try ComparisonCommand(arguments: args + ["--output", bundle.appendingPathComponent("bad.json").path], directory: root)
        do { _ = try await protected.run(reader: reader); XCTFail("input write accepted") } catch {}
    }
    func testFailuresAndRepresentationOnlyDifference() async throws {
        let pair = ExampleSnapshots.pair(architecture: .arm64)
        let command = try ComparisonCommand(arguments: args)
        do { _ = try await command.run(reader: FailingReader()); XCTFail("inspection failure hidden") } catch {}
        let empty = EntitlementSnapshot(sourceName: "A.app", signingIdentifier: "example", architecture: .arm64, entitlements: .init())
        let absent = EntitlementSnapshot(sourceName: "B.app", signingIdentifier: "example", architecture: .arm64, presence: .notPresent, entitlements: .init())
        let result = try await command.run(reader: PairReader(before: empty, after: absent)); XCTAssertEqual(result.exitStatus, 1)
        let wrong = EntitlementSnapshot(sourceName: "A.app", signingIdentifier: "example", architecture: .x86_64, entitlements: pair.0.entitlements)
        do { _ = try await command.run(reader: PairReader(before: wrong, after: wrong)); XCTFail("fallback accepted") } catch {}
    }
}
private actor PairReader: SnapshotReading {
    let before: EntitlementSnapshot, after: EntitlementSnapshot
    var count = 0
    init(before: EntitlementSnapshot, after: EntitlementSnapshot) { self.before = before; self.after = after }
    func read(at url: URL, architecture: Architecture) async throws -> EntitlementSnapshot { count += 1; return count % 2 == 1 ? before : after }
}
private struct FailingReader: SnapshotReading {
    func read(at url: URL, architecture: Architecture) async throws -> EntitlementSnapshot { throw CancellationError() }
}
