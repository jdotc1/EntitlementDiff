import AppKit
import SwiftUI

/// NSTextField delivers raw edits without SwiftUI String canonical-equivalence coalescing.
struct ExactChildKeyField: NSViewRepresentable {
    @Binding var input: ExactChildKeyInput
    let edited: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator(self) }
    func makeNSView(context: Context) -> NSTextField {
        let field = NSTextField(string: input.value)
        field.placeholderString = "Exact child key"
        field.isEditable = true
        field.isSelectable = true
        field.bezelStyle = .roundedBezel
        field.delegate = context.coordinator
        field.setContentHuggingPriority(.defaultLow, for: .horizontal)
        return field
    }
    func updateNSView(_ field: NSTextField, context: Context) {
        context.coordinator.owner = self
        if !field.stringValue.utf8.elementsEqual(input.value.utf8) {
            field.stringValue = input.value
        }
    }
    static func dismantleNSView(_ field: NSTextField, coordinator: Coordinator) {
        field.delegate = nil
    }
    final class Coordinator: NSObject, NSTextFieldDelegate {
        var owner: ExactChildKeyField
        init(_ owner: ExactChildKeyField) { self.owner = owner }
        func controlTextDidChange(_ notification: Notification) {
            guard let field = notification.object as? NSTextField else { return }
            owner.input = ExactChildKeyInput(value: field.stringValue)
            owner.edited()
        }
    }
}
