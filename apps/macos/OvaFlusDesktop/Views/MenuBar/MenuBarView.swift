import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Portfolio summary
            VStack(alignment: .leading, spacing: 4) {
                Text("Portfolio")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("$\(appState.portfolioTotalValue, specifier: "%.2f")")
                    .font(.title3.weight(.bold))
                Text(appState.dayChangeFormatted)
                    .font(.caption)
                    .foregroundStyle(appState.dayChange >= 0 ? .green : .red)
            }

            Divider()

            // Budget summary
            VStack(alignment: .leading, spacing: 4) {
                Text("Monthly Budget")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack {
                    Text("$\(appState.monthlyBudgetSpent, specifier: "%.0f")")
                        .fontWeight(.medium)
                    Text("of $\(appState.monthlyBudgetLimit, specifier: "%.0f")")
                        .foregroundStyle(.secondary)
                }
                ProgressView(value: appState.monthlyBudgetLimit > 0
                    ? min(appState.monthlyBudgetSpent / appState.monthlyBudgetLimit, 1.0)
                    : 0)
                    .tint(appState.budgetRemainingPercent < 10 ? .red :
                          appState.budgetRemainingPercent < 30 ? .orange : .green)
            }

            Divider()

            // Quick actions
            Button {
                NotificationCenter.default.post(name: .newTransaction, object: nil)
                NSApp.activate(ignoringOtherApps: true)
            } label: {
                Label("Quick Add Transaction", systemImage: "plus.circle")
            }
            .buttonStyle(.plain)

            Button {
                NSApp.activate(ignoringOtherApps: true)
            } label: {
                Label("Open OvaFlus", systemImage: "macwindow")
            }
            .buttonStyle(.plain)
        }
        .padding()
        .frame(width: 240)
    }
}
