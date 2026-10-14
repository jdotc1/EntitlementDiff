import Foundation

@main
struct GenerateExample {
    static func main() throws {
        guard CommandLine.arguments.count == 2 else {
            throw NSError(domain: "GenerateExample", code: 2, userInfo: [NSLocalizedDescriptionKey: "Pass the Examples directory."])
        }
        let destination = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
        let pair = ExampleSnapshots.pair(architecture: .arm64)
        let report = try ComparisonReport(previous: pair.previous, current: pair.current)
        try report.jsonData().write(to: destination.appendingPathComponent("example-report.json"), options: .atomic)
        try Data(report.text().utf8).write(to: destination.appendingPathComponent("example-report.txt"), options: .atomic)
    }
}
