import AppKit
import SwiftUI
import EntitlementDiffCore
import EntitlementDiffModel
import EntitlementDiffSecurity

@main
@MainActor
struct EntitlementDiffApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    @State private var model: ComparisonModel
    @State private var actions: AppActions

    init() {
        let model = ComparisonModel(reader: SecurityEntitlementReader())
        _model = State(initialValue: model)
        _actions = State(initialValue: AppActions(model: model))
    }

    var body: some Scene {
        Window("EntitlementDiff", id: "comparison") {
            ContentView(model: model, actions: actions)
        }
        .defaultSize(width: 1_120, height: 800)
        .windowResizability(.contentMinSize)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Choose Previous Application…") { actions.choose(.previous) }
                    .keyboardShortcut("1", modifiers: .command)
                    .disabled(actions.isBusy)
                Button("Choose Current Application…") { actions.choose(.current) }
                    .keyboardShortcut("2", modifiers: .command)
                    .disabled(actions.isBusy)
            }
            CommandMenu("Comparison") {
                Button("Load Synthetic Example") { actions.loadExample() }
                    .keyboardShortcut("d", modifiers: [.command, .shift])
                    .disabled(actions.isBusy)
                Button("Swap Previous and Current") { actions.swap() }
                    .keyboardShortcut("x", modifiers: [.command, .shift])
                    .disabled(!model.canSwap || actions.isBusy)
                Button("Clear Both Inputs") { actions.clear() }
                    .keyboardShortcut("k", modifiers: [.command, .shift])
                    .disabled(!model.hasInputs || actions.isBusy)
                Divider()
                Button("Copy Complete Text Report") { actions.copyReport() }
                    .keyboardShortcut("c", modifiers: [.command, .shift])
                    .disabled(model.report == nil || actions.isBusy)
                Button("Export Complete JSON Report…") { actions.exportJSON() }
                    .keyboardShortcut("s", modifiers: [.command, .shift])
                    .disabled(model.report == nil || actions.isBusy)
            }
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }
}
