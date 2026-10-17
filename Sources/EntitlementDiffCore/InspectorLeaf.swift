import Foundation

/// A captured scalar value, never a display preview or an absent/container placeholder.
public struct InspectorLeaf: Sendable {
    public let value: EntitlementValue

    public init?(_ value: EntitlementValue?) {
        guard let value else { return nil }
        switch value {
        case .array, .dictionary: return nil
        default: self.value = value
        }
    }

    /// Uses the same exact tagged scalar encoding as complete reports.
    public func jsonData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        return try encoder.encode(value)
    }
}

/// Build off MainActor. Indexing is cancellable; rendering visits only the chosen page.
public struct LeafValueDocument: Sendable {
    public static let stringScalarsPerPage = 512
    // Whole triples make concatenated page base64 equal the complete base64 value.
    public static let dataBytesPerPage = 768
    public let leaf: InspectorLeaf
    public let pageCount: Int
    private let stringPages: [Range<String.Index>]

    public init(leaf: InspectorLeaf) throws {
        try Task.checkCancellation()
        self.leaf = leaf
        var pages: [Range<String.Index>] = []
        switch leaf.value {
        case .string(let string):
            let scalars = string.unicodeScalars
            var start = scalars.startIndex
            while start < scalars.endIndex {
                try Task.checkCancellation()
                let end = scalars.index(start, offsetBy: Self.stringScalarsPerPage,
                                        limitedBy: scalars.endIndex) ?? scalars.endIndex
                pages.append(start..<end)
                start = end
            }
            if pages.isEmpty { pages.append(start..<start) }
            pageCount = pages.count
        case .data(let data):
            pageCount = max(1, data.count / Self.dataBytesPerPage + (data.count % Self.dataBytesPerPage == 0 ? 0 : 1))
        default:
            pageCount = 1
        }
        stringPages = pages
    }

    public func text(onPage requestedPage: Int) -> String {
        let page = max(0, min(requestedPage, pageCount - 1))
        switch leaf.value {
        case .string(let string):
            // Preserve scalar boundaries and escape after slicing, so combining marks
            // and escaped controls cannot bypass the per-page rendering budget.
            return DisplayText.quoted(String(string.unicodeScalars[stringPages[page]]))
        case .data(let data):
            let offset = page * Self.dataBytesPerPage
            let start = data.index(data.startIndex, offsetBy: offset)
            let end = data.index(start, offsetBy: min(Self.dataBytesPerPage, data.count - offset))
            return data[start..<end].base64EncodedString()
        default:
            return leaf.value.rendered
        }
    }
}

extension InspectorRow {
    public var hasLeafValue: Bool { InspectorLeaf(previous) != nil || InspectorLeaf(current) != nil }
}
