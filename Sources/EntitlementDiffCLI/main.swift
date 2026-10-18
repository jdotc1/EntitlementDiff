import Foundation
import Darwin
import EntitlementDiffCLIKit
import EntitlementDiffSecurity

let arguments = Array(CommandLine.arguments.dropFirst())
if arguments == ["--help"] {
    do { try FileHandle.standardOutput.write(contentsOf: Data((ComparisonCommand.usage + "\n").utf8)) }
    catch { exit(2) }
    exit(0)
}
do {
    let command = try ComparisonCommand(arguments: arguments)
    let result = try await command.run(reader: SecurityEntitlementReader())
    try FileHandle.standardOutput.write(contentsOf: result.standardOutput)
    exit(result.exitStatus)
} catch {
    // Diagnostics are separate from the path-free JSON report stream.
    try? FileHandle.standardError.write(contentsOf: Data(("entitlementdiff-cli: " + error.localizedDescription + "\n").utf8))
    exit(2)
}
