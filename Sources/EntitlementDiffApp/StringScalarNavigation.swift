import Foundation
import EntitlementDiffCore

/// Pane-local navigation, independent of literal search and difference history.
struct StringScalarNavigation {
    private(set) var input = "1"
    private(set) var position: LeafValueDocument.ScalarPosition?
    private(set) var error: String?
    private(set) var revision = UUID()
    mutating func setInput(_ text: String) {
        input = String(decoding: text.utf8.prefix(21), as: UTF8.self); error = nil
    }
    @discardableResult
    mutating func go(document: LeafValueDocument) -> Bool {
        let bytes = Array(input.utf8.prefix(21))
        guard let count = document.stringScalarCount else { return false }
        guard !bytes.isEmpty, bytes.count <= 20, bytes.allSatisfy({ $0 >= 48 && $0 <= 57 }),
              let number = Int(input), number >= 1,
              let found = document.scalarPosition(at: number - 1) else {
            error = "Enter a scalar position from 1 through \(count + 1) (EOF)."; return false
        }
        position = found; error = nil; revision = UUID(); return true
    }
    mutating func reset() { self = .init() }
}
