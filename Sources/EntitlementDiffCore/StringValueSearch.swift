import Foundation

/// Incremental literal UTF-8 search. Never materializes the complete source as bytes.
public struct StringValueSearch: Sendable {
    public static let queryByteLimit = 1_024
    public static let stepByteLimit = 32_768
    public enum InputError: Error { case invalidQuery }
    public struct Match: Sendable, Equatable {
        public let byteOffset: Int
        public let scalarOffset: Int
        public var pageIndex: Int { scalarOffset / LeafValueDocument.stringScalarsPerPage }
    }
    public enum Step: Sendable, Equatable { case match(Match), more, end }
    private let source: String
    private let pattern: [UInt8]
    private let prefix: [Int]
    private var index: String.UTF8View.Index
    private var matched = 0
    private var byteOffset = 0
    private var scalarOffset = 0
    private var scalarStarts: [Int]

    public init(source: String, query: String) throws {
        let bytes = Array(query.utf8.prefix(Self.queryByteLimit + 1))
        guard !bytes.isEmpty, bytes.count <= Self.queryByteLimit else { throw InputError.invalidQuery }
        self.source = source
        pattern = bytes
        index = source.utf8.startIndex
        scalarStarts = Array(repeating: 0, count: bytes.count)
        var table = Array(repeating: 0, count: bytes.count)
        var length = 0
        for i in bytes.indices.dropFirst() {
            while length > 0 && bytes[i] != bytes[length] { length = table[length - 1] }
            if bytes[i] == bytes[length] { length += 1 }
            table[i] = length
        }
        prefix = table
    }

    /// Testable smaller budgets are allowed; callers cannot exceed the fixed step ceiling.
    public mutating func step(byteLimit: Int = Self.stepByteLimit) throws -> Step {
        try Task.checkCancellation()
        let bytes = source.utf8
        let limit = min(Self.stepByteLimit, max(1, byteLimit))
        var consumed = 0
        while index != bytes.endIndex && consumed < limit {
            if consumed % 256 == 0 { try Task.checkCancellation() }
            let byte = bytes[index]
            // A valid query starts at a scalar boundary. Track scalar positions in a bounded ring.
            scalarStarts[byteOffset % pattern.count] = scalarOffset
            if byte & 0xC0 != 0x80 { scalarOffset += 1 }
            while matched > 0 && byte != pattern[matched] { matched = prefix[matched - 1] }
            if byte == pattern[matched] { matched += 1 }
            bytes.formIndex(after: &index)
            byteOffset += 1
            consumed += 1
            if matched == pattern.count {
                let start = byteOffset - pattern.count
                let scalar = scalarStarts[start % pattern.count]
                matched = prefix[matched - 1] // Preserve overlapping matches for Find Next.
                return .match(.init(byteOffset: start, scalarOffset: scalar))
            }
        }
        return index == bytes.endIndex ? .end : .more
    }
}
