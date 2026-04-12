import SwiftUI

@main
struct TodoAppApp: App {
    @State private var viewModel = TodoViewModel()

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
            CommandGroup(replacing: .help) { }

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
    }
}
