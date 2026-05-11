import SwiftUI
import AppKit

@main
struct TodoAppApp: App {
    @State private var viewModel = TodoViewModel()
    @AppStorage("todoApp.denseModeEnabled") private var denseModeEnabled = false
    @AppStorage("todoApp.fallingCompletedEnabled") private var fallingCompletedEnabled = false

    private let releasesURL = URL(string: "https://github.com/hy0brrr/todo-app/releases")!
    private var interfaceDensity: InterfaceDensity {
        denseModeEnabled ? .dense : .regular
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(viewModel)
                .environment(\.interfaceDensity, interfaceDensity)
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

            CommandMenu("Settings") {
                Button("New Partition...") {
                    viewModel.addPartition()
                }
                .keyboardShortcut("n", modifiers: .command)

                Button("Manage Partitions...") {
                    viewModel.showManagePartitions = true
                }

                Divider()

                Toggle("Dense Mode", isOn: $denseModeEnabled)
                Toggle("Falling Completed", isOn: $fallingCompletedEnabled)
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
