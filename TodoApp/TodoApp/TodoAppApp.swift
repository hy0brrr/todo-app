import SwiftUI
import AppKit

@main
struct TodoAppApp: App {
    @State private var viewModel = TodoViewModel()

    private let releasesURL = URL(string: "https://github.com/hy0brrr/todo-app/releases")!

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(viewModel)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 400, height: 750)
        .commands {
            // Replace the default "New Window" command
            CommandGroup(replacing: .newItem) { }

            // Remove Edit menu
            CommandGroup(replacing: .undoRedo) { }
            CommandGroup(replacing: .pasteboard) { }

            // Remove View menu
            CommandGroup(replacing: .toolbar) { }
            CommandGroup(replacing: .sidebar) { }

            // Remove Window menu
            CommandGroup(replacing: .windowSize) { }
            CommandGroup(replacing: .windowList) { }
            CommandGroup(replacing: .singleWindowList) { }

            // Remove Help menu
            CommandGroup(replacing: .help) {
                Button("Check for Updates...") {
                    NSWorkspace.shared.open(releasesURL)
                }
            }

            // Custom Partition menu
            CommandMenu("Partition") {
                Button("New Partition...") {
                    viewModel.addPartition()
                }
                .keyboardShortcut("n", modifiers: .command)

                Divider()

                Button("Manage Partitions...") {
                    viewModel.showManagePartitions = true
                }
            }
        }
#if DEBUG
        .commands {
            CommandMenu("Debug Data") {
                Button("Use Demo Data") {
                    viewModel.loadDemoDataForDebug()
                }

                Button("Use Local Data") {
                    viewModel.loadPersistedState()
                }

                Divider()

                Button("Clear Local Data") {
                    viewModel.clearPersistedStateForDebug()
                }
            }
        }
#endif
    }
}
