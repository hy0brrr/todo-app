import SwiftUI

@main
struct TodoAppApp: App {
    @State private var viewModel = TodoViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(viewModel)
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 400, height: 750)
        .commands {
            // Replace the default "New Window" command
            CommandGroup(replacing: .newItem) { }

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
