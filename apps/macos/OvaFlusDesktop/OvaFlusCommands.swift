import SwiftUI

struct OvaFlusCommands: Commands {
    var body: some Commands {
        // File menu
        CommandGroup(after: .newItem) {
            Button("New Transaction") {
                NotificationCenter.default.post(name: .newTransaction, object: nil)
            }
            .keyboardShortcut("n", modifiers: .command)

            Divider()

            Button("Import CSV...") {
                NotificationCenter.default.post(name: .importCSV, object: nil)
            }
            .keyboardShortcut("i", modifiers: .command)

            Button("Export Data...") {
                NotificationCenter.default.post(name: .exportData, object: nil)
            }
            .keyboardShortcut("e", modifiers: .command)
        }

        // View menu
        CommandGroup(after: .sidebar) {
            Button("Toggle Sidebar") {
                NSApp.keyWindow?.firstResponder?.tryToPerform(
                    #selector(NSSplitViewController.toggleSidebar(_:)), with: nil
                )
            }
            .keyboardShortcut("s", modifiers: [.command, .control])

            Button("Refresh") {
                NotificationCenter.default.post(name: .refreshData, object: nil)
            }
            .keyboardShortcut("r", modifiers: .command)
        }
    }
}

extension Notification.Name {
    static let newTransaction = Notification.Name("newTransaction")
    static let importCSV = Notification.Name("importCSV")
    static let exportData = Notification.Name("exportData")
    static let refreshData = Notification.Name("refreshData")
}
