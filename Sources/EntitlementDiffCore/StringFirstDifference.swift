import Foundation

/// Explicit bounded comparison of captured originals; no normalization or whole-source byte arrays.
public struct StringFirstDifference: Sendable {
    public static let stepByteLimit = 32_768
    public struct Position: Sendable, Equatable {
        public let byteOffset: Int
        public let scalarOffset: Int
        public let previousScalar: Unicode.Scalar?
        public let currentScalar: Unicode.Scalar?
        public var previousByteCount: Int { previousScalar.map { String($0).utf8.count } ?? 0 }
        public var currentByteCount: Int { currentScalar.map { String($0).utf8.count } ?? 0 }
        public var previousDetail: StringScalarDetail { StringScalarDetail(scalar: previousScalar) }
        public var currentDetail: StringScalarDetail { StringScalarDetail(scalar: currentScalar) }
        public var pageIndex: Int { scalarOffset / LeafValueDocument.stringScalarsPerPage }
    }
    public enum Step: Sendable, Equatable { case more, equal, difference(Position) }
    private let previous: String
    private let current: String
    private var previousIndex: String.UnicodeScalarView.Index
    private var currentIndex: String.UnicodeScalarView.Index
    private var byteOffset = 0
    private var scalarOffset = 0

    public init(previous: String, current: String) {
        self.previous = previous; self.current = current
        previousIndex = previous.unicodeScalars.startIndex
        currentIndex = current.unicodeScalars.startIndex
    }

    /// Budget counts both sources' UTF-8 bytes; at least one pair (up to eight bytes) fits.
    public mutating func step(byteLimit: Int = Self.stepByteLimit) throws -> Step {
        try Task.checkCancellation()
        let limit = min(Self.stepByteLimit, max(8, byteLimit))
        let left = previous.unicodeScalars, right = current.unicodeScalars
        var consumed = 0, pairs = 0
        while true {
            if pairs % 64 == 0 { try Task.checkCancellation() }
            let aEnded = previousIndex == left.endIndex, bEnded = currentIndex == right.endIndex
            if aEnded && bEnded { return .equal }
            // Reserve the maximum scalar-pair size before reading either source.
            guard limit - consumed >= 8 else { return .more }
            let a = aEnded ? nil : left[previousIndex]
            let b = bEnded ? nil : right[currentIndex]
            let aBytes = a.map { String($0).utf8.count } ?? 0
            let bBytes = b.map { String($0).utf8.count } ?? 0
            guard consumed + aBytes + bBytes <= limit else { return .more }
            if a != b {
                return .difference(.init(byteOffset: byteOffset, scalarOffset: scalarOffset,
                                         previousScalar: a, currentScalar: b))
            }
            consumed += aBytes + bBytes; pairs += 1
            byteOffset += aBytes; scalarOffset += 1
            left.formIndex(after: &previousIndex); right.formIndex(after: &currentIndex)
        }
    }
}
