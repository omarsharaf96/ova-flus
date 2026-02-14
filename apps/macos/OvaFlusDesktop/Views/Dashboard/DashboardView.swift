import SwiftUI
import Charts

struct DashboardView: View {
    @EnvironmentObject var appState: AppState
    @State private var budgets: [Budget] = []
    @State private var recentTransactions: [Transaction] = []
    @State private var spendingData: [SpendingDataPoint] = []

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Net worth summary
                netWorthSection

                // Budget overview + Portfolio value
                HStack(alignment: .top, spacing: 16) {
                    budgetOverviewGrid
                    portfolioValueCard
                }

                // Spending chart
                spendingChartSection

                // Recent transactions table
                recentTransactionsSection
            }
            .padding()
        }
        .navigationTitle("Dashboard")
    }

    // MARK: - Net Worth Summary

    private var netWorthSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Net Worth")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("$\(appState.netWorth, specifier: "%.2f")")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("Today")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(appState.dayChangeFormatted)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(appState.dayChange >= 0 ? .green : .red)
            }
        }
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    // MARK: - Budget Overview Grid

    private var budgetOverviewGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Budget Overview")
                .font(.headline)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(budgets) { budget in
                    BudgetCardView(budget: budget)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    // MARK: - Portfolio Value Card

    private var portfolioValueCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Portfolio")
                .font(.headline)
            Text("$\(appState.portfolioTotalValue, specifier: "%.2f")")
                .font(.system(size: 24, weight: .bold, design: .rounded))
            Text(appState.dayChangeFormatted)
                .font(.subheadline)
                .foregroundStyle(appState.dayChange >= 0 ? .green : .red)
        }
        .frame(width: 220)
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    // MARK: - Spending Chart

    private var spendingChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Monthly Spending")
                .font(.headline)

            Chart(spendingData) { point in
                BarMark(
                    x: .value("Category", point.category),
                    y: .value("Amount", point.amount)
                )
                .foregroundStyle(by: .value("Category", point.category))
            }
            .frame(height: 200)
        }
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    // MARK: - Recent Transactions

    private var recentTransactionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Transactions")
                    .font(.headline)
                Spacer()
                Button("View All") {
                    // Navigate to transactions
                }
            }

            Table(recentTransactions) {
                TableColumn("Date") { tx in
                    Text(tx.date, style: .date)
                }
                .width(min: 80, ideal: 100)

                TableColumn("Merchant") { tx in
                    Text(tx.merchant)
                }
                .width(min: 120, ideal: 160)

                TableColumn("Category") { tx in
                    Text(tx.category)
                }
                .width(min: 80, ideal: 100)

                TableColumn("Amount") { tx in
                    Text("$\(tx.amount, specifier: "%.2f")")
                        .foregroundStyle(tx.amount < 0 ? .red : .green)
                }
                .width(min: 80, ideal: 100)
            }
            .frame(height: 200)
        }
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }
}

// MARK: - Supporting Views

struct BudgetCardView: View {
    let budget: Budget

    var percentUsed: Double {
        guard budget.limit > 0 else { return 0 }
        return min(budget.spent / budget.limit, 1.0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(budget.name)
                .font(.subheadline.weight(.medium))
            ProgressView(value: percentUsed)
                .tint(percentUsed > 0.9 ? .red : percentUsed > 0.7 ? .orange : .green)
            HStack {
                Text("$\(budget.spent, specifier: "%.0f")")
                    .font(.caption)
                Spacer()
                Text("$\(budget.limit, specifier: "%.0f")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(10)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
        )
    }
}

struct SpendingDataPoint: Identifiable {
    let id = UUID()
    let category: String
    let amount: Double
}
