import OSLog
import SwiftData
import SwiftUI
import UserNotifications

struct SettingsView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.modelContext) private var modelContext
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("budgetAlerts") private var budgetAlerts = true
    @AppStorage("stockAlerts") private var stockAlerts = true
    @AppStorage("budgetAlertThreshold") private var budgetAlertThreshold: Double = 0.8
    @AppStorage("biometricEnabled") private var biometricEnabled = false
    @State private var showExportConfirmation = false
    @State private var showResetConfirmation = false
    @State private var showDeleteAccountConfirmation = false
    @State private var resetError: String?

    private let logger = Logger(subsystem: "com.ovaflus.app", category: "settings")

    private var currentPlanLabel: String {
        authManager.currentUser?.subscriptionTier.rawValue.capitalized ?? "Free"
    }

    var body: some View {
        List {
            // Subscription
            Section {
                NavigationLink {
                    UpgradePlanView()
                } label: {
                    HStack {
                        Label("Subscription", systemImage: "crown.fill")
                            .foregroundStyle(.orange)
                        Spacer()
                        Text(currentPlanLabel)
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                    }
                }
            }

            // Appearance
            Section("Appearance") {
                Toggle("Dark Mode", isOn: $isDarkMode)
                    .tint(.blue)
            }

            // Notifications
            Section("Notifications") {
                Toggle("Enable Notifications", isOn: $notificationsEnabled)
                    .tint(.blue)
                    .onChange(of: notificationsEnabled) { _, newValue in
                        if newValue {
                            Task { _ = await NotificationService.shared.requestAuthorization() }
                            NotificationService.shared.scheduleWeeklySummary()
                        } else {
                            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["weekly-summary"])
                        }
                    }
                if notificationsEnabled {
                    Toggle("Budget Alerts", isOn: $budgetAlerts)
                        .tint(.blue)
                    Toggle("Stock Price Alerts", isOn: $stockAlerts)
                        .tint(.blue)
                }
            }

            if notificationsEnabled {
                Section("Budget Alerts") {
                    HStack {
                        Text("Alert Threshold")
                        Spacer()
                        Text("\(Int(budgetAlertThreshold * 100))%")
                            .foregroundColor(.secondary)
                    }
                    Slider(value: $budgetAlertThreshold, in: 0.5...1.0, step: 0.1)
                        .tint(.accentColor)
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
                NavigationLink {
                    BankAccountsView()
                } label: {
                    Label("Linked Banks", systemImage: "building.columns")
                }
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

            // Danger Zone
            Section {
                Button(role: .destructive) {
                    showResetConfirmation = true
                } label: {
                    Label("Reset Local Data", systemImage: "arrow.counterclockwise")
                }

                Button(role: .destructive) {
                    showDeleteAccountConfirmation = true
                } label: {
                    Label("Delete Account", systemImage: "person.crop.circle.badge.minus")
                }
            } header: {
                Text("Danger Zone")
            } footer: {
                Text("Reset Local Data clears all budgets, transactions, holdings, and goals from this device. Delete Account permanently removes your account and signs you out.")
            }

            if let resetError {
                Section {
                    Text(resetError)
                        .foregroundStyle(.red)
                        .font(.caption)
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
        .alert("Reset Local Data?", isPresented: $showResetConfirmation) {
            Button("Reset", role: .destructive) {
                resetLocalData()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will delete all budgets, transactions, holdings, goals, and watchlist items stored on this device. Your account will remain active.")
        }
        .alert("Delete Account?", isPresented: $showDeleteAccountConfirmation) {
            Button("Delete Account", role: .destructive) {
                resetLocalData()
                authManager.signOut()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will clear all local data and sign you out. Contact support to fully remove your account from our servers.")
        }
    }

    private func resetLocalData() {
        logger.info("Resetting all local user data")
        do {
            try modelContext.delete(model: BudgetModel.self)
            try modelContext.delete(model: TransactionModel.self)
            try modelContext.delete(model: HoldingModel.self)
            try modelContext.delete(model: GoalModel.self)
            try modelContext.delete(model: WatchlistItemModel.self)
            try modelContext.delete(model: LinkedBankAccountModel.self)
            resetAppStorage()
            resetError = nil
            logger.info("Local data reset complete")
        } catch {
            resetError = "Reset failed: \(error.localizedDescription)"
            logger.error("Local data reset failed: \(error.localizedDescription)")
        }
    }

    private func resetAppStorage() {
        isDarkMode = false
        notificationsEnabled = true
        budgetAlerts = true
        stockAlerts = true
        budgetAlertThreshold = 0.8
        biometricEnabled = false
        UserDefaults.standard.removeObject(forKey: "biometric_enabled")
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environmentObject(AuthManager())
    }
}
