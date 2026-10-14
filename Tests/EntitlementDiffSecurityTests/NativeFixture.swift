import Darwin
import Foundation
import EntitlementDiffCore

/// Only test-owned temporary artifacts are compiled, signed or removed.
/// The production reader has no Process, shell, or code-execution capability.
@MainActor
final class NativeFixture {
    static let identifier = "org.example.EntitlementDiffFixture"
    let root: URL
    let app: URL
    let executable: URL
    let resource: URL
    let executionMarker: URL
    private var sequence = 0

    init() throws {
        root = FileManager.default.temporaryDirectory.appendingPathComponent("EntitlementDiffNative-" + UUID().uuidString, isDirectory: true)
        app = root.appendingPathComponent("Fixture ; quote' space.app", isDirectory: true)
        executable = app.appendingPathComponent("Contents/MacOS/Main")
        resource = app.appendingPathComponent("Contents/Resources/note.txt")
        executionMarker = root.appendingPathComponent("EXECUTED")
        do {
            try FileManager.default.createDirectory(at: executable.deletingLastPathComponent(), withIntermediateDirectories: true)
            try FileManager.default.createDirectory(at: resource.deletingLastPathComponent(), withIntermediateDirectories: true)
            let info: [String: Any] = ["CFBundleIdentifier": Self.identifier, "CFBundleExecutable": "Main", "CFBundlePackageType": "APPL", "CFBundleName": "Fixture"]
            try plist(info).write(to: app.appendingPathComponent("Contents/Info.plist"))
            try Data("original resource".utf8).write(to: resource)
        } catch {
            try? FileManager.default.removeItem(at: root)
            throw error
        }
    }

    deinit { try? FileManager.default.removeItem(at: root) }

    func build(architecture: Architecture, entitlements: [String: Any]? = nil, signed: Bool = true) throws {
        try compile(architecture, output: executable)
        if signed {
            try sign(app, entitlements: entitlements)
        } else {
            // arm64 linkers may apply ad-hoc signatures automatically. Remove
            // one if present; the test then independently asserts unsigned state.
            try run("/usr/bin/codesign", ["--remove-signature", executable.path], allowedStatuses: [0, 1])
        }
    }

    func buildUniversalWithDistinctEntitlements() throws {
        var slices: [URL] = []
        for architecture in Architecture.allCases {
            let slice = root.appendingPathComponent("slice-" + architecture.rawValue)
            try compile(architecture, output: slice)
            try sign(slice, entitlements: ["test.slice": architecture.rawValue])
            slices.append(slice)
        }
        // Deliberately assemble independently signed slices. This is an
        // extraction fixture, not a claim of a valid distribution bundle seal.
        try run("/usr/bin/xcrun", ["lipo", "-create"] + slices.map(\.path) + ["-output", executable.path])
    }

    private func compile(_ architecture: Architecture, output: URL) throws {
        let source = root.appendingPathComponent("fixture.c")
        // The marker makes accidental execution observable. No test launches it.
        let escapedPath = executionMarker.path.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        let c = "#include <stdio.h>\nint main(void) { FILE *f = fopen(\"\(escapedPath)\", \"w\"); if(f) fclose(f); return 0; }\n"
        try Data(c.utf8).write(to: source)
        try run("/usr/bin/xcrun", ["clang", "-arch", architecture.rawValue, "-mmacosx-version-min=14.0", source.path, "-o", output.path])
    }

    private func sign(_ target: URL, entitlements: [String: Any]?) throws {
        var arguments = ["--force", "--sign", "-", "--identifier", Self.identifier]
        if let entitlements {
            let file = root.appendingPathComponent("entitlements-\(sequence).plist")
            sequence += 1
            try plist(entitlements).write(to: file)
            arguments += ["--entitlements", file.path]
        }
        try run("/usr/bin/codesign", arguments + [target.path])
    }

    private func plist(_ values: [String: Any]) throws -> Data {
        try PropertyListSerialization.data(fromPropertyList: values, format: .xml, options: 0)
    }

    private func run(_ executable: String, _ arguments: [String], allowedStatuses: Set<Int32> = [0]) throws {
        let logURL = root.appendingPathComponent("tool-\(sequence).log")
        sequence += 1
        guard FileManager.default.createFile(atPath: logURL.path, contents: nil) else { throw FixtureError("Cannot create test log.") }
        let handle = try FileHandle(forWritingTo: logURL)
        defer { try? handle.close() }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        process.standardOutput = handle
        process.standardError = handle
        try process.run()
        let deadline = Date().addingTimeInterval(45)
        while process.isRunning && Date() < deadline { Thread.sleep(forTimeInterval: 0.05) }
        if process.isRunning {
            process.terminate()
            Thread.sleep(forTimeInterval: 0.2)
            if process.isRunning { Darwin.kill(process.processIdentifier, SIGKILL) }
            process.waitUntilExit()
            throw FixtureError("Test-owned subprocess timed out: \(executable)")
        }
        process.waitUntilExit()
        guard allowedStatuses.contains(process.terminationStatus) else {
            let data = try Data(contentsOf: logURL)
            let message = String(decoding: data.prefix(16_384), as: UTF8.self)
            throw FixtureError("\(executable) failed (\(process.terminationStatus)): \(message)")
        }
    }
}

private struct FixtureError: Error, LocalizedError {
    let message: String
    init(_ message: String) { self.message = message }
    var errorDescription: String? { message }
}
