import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }

            NotificationSettingsView()
                .tabItem {
                    Label("Notifications", systemImage: "bell")
                }

            SecuritySettingsView()
                .tabItem {
                    Label("Security", systemImage: "lock.shield")
                }

            DataSettingsView()
                .tabItem {
                    Label("Data", systemImage: "externaldrive")
                }

            AccountSettingsView()
                .tabItem {
                    Label("Account", systemImage: "person.circle")
                }
        }
        .frame(width: 500, height: 350)
    }
}

// MARK: - General Settings

struct GeneralSettingsView: View {
    @AppStorage("theme") private var theme = "system"
    @AppStorage("currency") private var currency = "USD"
    @AppStorage("language") private var language = "en"

    var body: some View {
        Form {
            Picker("Appearance", selection: $theme) {
                Text("System").tag("system")
                Text("Light").tag("light")
                Text("Dark").tag("dark")
            }
            Picker("Currency", selection: $currency) {
                Text("USD ($)").tag("USD")
                Text("EUR (\u{20AC})").tag("EUR")
                Text("GBP (\u{00A3})").tag("GBP")
                Text("CAD (C$)").tag("CAD")
            }
            Picker("Language", selection: $language) {
                Text("English").tag("en")
                Text("Spanish").tag("es")
                Text("French").tag("fr")
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - Notification Settings

struct NotificationSettingsView: View {
    @AppStorage("notifyBudgetAlerts") private var budgetAlerts = true
    @AppStorage("notifyTransactions") private var transactionAlerts = true
    @AppStorage("notifyMarketUpdates") private var marketUpdates = false
    @AppStorage("notifyWeeklyReport") private var weeklyReport = true

    var body: some View {
        Form {
            Toggle("Budget threshold alerts", isOn: $budgetAlerts)
            Toggle("New transaction notifications", isOn: $transactionAlerts)
            Toggle("Market price alerts", isOn: $marketUpdates)
            Toggle("Weekly spending report", isOn: $weeklyReport)
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - Security Settings

struct SecuritySettingsView: View {
    @AppStorage("biometricAuth") private var biometricAuth = false
    @AppStorage("sessionTimeout") private var sessionTimeout = 30

    var body: some View {
        Form {
            Toggle("Require Touch ID / Password on launch", isOn: $biometricAuth)
            Picker("Session timeout", selection: $sessionTimeout) {
                Text("15 minutes").tag(15)
                Text("30 minutes").tag(30)
                Text("1 hour").tag(60)
                Text("Never").tag(0)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - Data Settings

struct DataSettingsView: View {
    var body: some View {
        Form {
            Section("Export") {
                Button("Export All Data as CSV...") {
                    exportData()
                }
                Button("Export Transactions...") {
                    exportTransactions()
                }
            }
            Section("Backup") {
                Button("Create Backup...") {
                    createBackup()
                }
                Button("Restore from Backup...") {
                    restoreBackup()
                }
            }
            Section("Import") {
                Button("Import Transactions from CSV...") {
                    importCSV()
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private func exportData() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.commaSeparatedText]
        panel.nameFieldStringValue = "ovaflus-export.csv"
        panel.runModal()
        // TODO: Write export data
    }

    private func exportTransactions() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.commaSeparatedText]
        panel.nameFieldStringValue = "transactions.csv"
        panel.runModal()
    }

    private func createBackup() {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "ovaflus-backup.json"
        panel.runModal()
    }

    private func restoreBackup() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.runModal()
    }

    private func importCSV() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.commaSeparatedText]
        panel.runModal()
    }
}

// MARK: - Account Settings

struct AccountSettingsView: View {
    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        Form {
            Section("Profile") {
                LabeledContent("Email") {
                    Text(authManager.currentUser?.email ?? "N/A")
                }
                LabeledContent("Name") {
                    Text(authManager.currentUser?.name ?? "N/A")
                }
                Button("Edit Profile...") {
                    // TODO: Open profile editor
                }
            }
            Section("Subscription") {
                LabeledContent("Plan") {
                    Text("Free")
                }
                Button("Upgrade to Premium...") {
                    // TODO: Open subscription page
                }
            }
            Section {
                Button("Sign Out", role: .destructive) {
                    authManager.signOut()
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}
