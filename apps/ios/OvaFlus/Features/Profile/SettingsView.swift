import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authManager: AuthManager
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("budgetAlerts") private var budgetAlerts = true
    @AppStorage("stockAlerts") private var stockAlerts = true
    @AppStorage("biometricEnabled") private var biometricEnabled = false
    @State private var showExportConfirmation = false

    var body: some View {
        List {
            // Appearance
            Section("Appearance") {
                Toggle("Dark Mode", isOn: $isDarkMode)
                    .tint(.blue)
            }

            // Notifications
            Section("Notifications") {
                Toggle("Enable Notifications", isOn: $notificationsEnabled)
                    .tint(.blue)
                if notificationsEnabled {
                    Toggle("Budget Alerts", isOn: $budgetAlerts)
                        .tint(.blue)
                    Toggle("Stock Price Alerts", isOn: $stockAlerts)
                        .tint(.blue)
                }
            }

            // Security
            Section("Security") {
                Toggle("Face ID / Touch ID", isOn: $biometricEnabled)
                    .tint(.blue)
                    .onChange(of: biometricEnabled) { _, newValue in
                        if newValue {
                            Task {
                                let success = await BiometricAuth.shared.authenticate(reason: "Enable biometric login")
                                if !success {
                                    biometricEnabled = false
                                }
                            }
                        }
                    }
                NavigationLink {
                    Text("Change Password View")
                } label: {
                    Text("Change Password")
                }
            }

            // Data
            Section("Data") {
                Button("Export All Data") {
                    showExportConfirmation = true
                }
                NavigationLink {
                    Text("Clear Cache View")
                } label: {
                    Text("Clear Cache")
                }
            }

            // About
            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("Build")
                    Spacer()
                    Text("1")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Settings")
        .alert("Export Data", isPresented: $showExportConfirmation) {
            Button("Export") {
                // Handle export
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will export all your financial data as a CSV file.")
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environmentObject(AuthManager())
    }
}
