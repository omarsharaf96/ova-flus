import SwiftUI

@main
struct OvaFlusDesktopApp: App {
    @StateObject private var authManager = AuthManager()
    @StateObject private var appState = AppState()

    var body: some Scene {
        // Main window
        WindowGroup {
            if authManager.isAuthenticated {
                MainWindowView()
                    .environmentObject(authManager)
                    .environmentObject(appState)
                    .frame(minWidth: 900, minHeight: 600)
            } else {
                LoginView()
                    .environmentObject(authManager)
                    .frame(width: 400, height: 500)
            }
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .commands {
            OvaFlusCommands()
        }

        // Menu bar extra
        MenuBarExtra("OvaFlus", systemImage: "chart.bar.fill") {
            MenuBarView()
                .environmentObject(appState)
        }
        .menuBarExtraStyle(.window)

        // Settings window
        Settings {
            SettingsView()
                .environmentObject(authManager)
        }
    }
}
