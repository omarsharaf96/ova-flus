import SwiftUI
import Charts

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Net Worth hero card
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Net Worth")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(viewModel.netWorth, format: .currency(code: "USD"))
                            .font(.system(size: 36, weight: .bold))
                        HStack(spacing: 4) {
                            Image(systemName: viewModel.portfolioDayChange >= 0 ? "arrow.up.right" : "arrow.down.right")
                            Text(viewModel.portfolioDayChange, format: .currency(code: "USD"))
                            Text("portfolio today")
                                .foregroundStyle(.secondary)
                        }
                        .font(.subheadline)
                        .foregroundStyle(viewModel.portfolioDayChange >= 0 ? .green : .red)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(.blue.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    // Stat tiles: Cash | Month Income | Month Spend
                    HStack(spacing: 12) {
                        StatTileView(
                            title: "Cash",
                            value: viewModel.cash,
                            icon: "banknote",
                            color: viewModel.cash >= 0 ? .green : .red
                        )
                        StatTileView(
                            title: "Month Income",
                            value: viewModel.monthIncome,
                            icon: "arrow.down.circle.fill",
                            color: .green
                        )
                        StatTileView(
                            title: "Month Spend",
                            value: viewModel.monthSpend,
                            icon: "arrow.up.circle.fill",
                            color: .red
                        )
                    }

                    // Budget Summary Card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Budget Summary")
                                .font(.headline)
                            Spacer()
                            NavigationLink("See All") {
                                BudgetListView()
                            }
                            .font(.subheadline)
                        }

                        if let summary = viewModel.budgetSummary {
                            // Spending donut chart
                            Chart(summary.categoryBreakdown, id: \.category) { item in
                                SectorMark(
                                    angle: .value("Amount", item.spent),
                                    innerRadius: .ratio(0.6),
                                    angularInset: 1.5
                                )
                                .foregroundStyle(by: .value("Category", item.category))
                                .cornerRadius(4)
                            }
                            .frame(height: 200)

                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Spent")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text(summary.totalSpent, format: .currency(code: "USD"))
                                        .font(.title3.bold())
                                }
                                Spacer()
                                VStack(alignment: .trailing) {
                                    Text("Remaining")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text(summary.totalBudget - summary.totalSpent, format: .currency(code: "USD"))
                                        .font(.title3.bold())
                                        .foregroundStyle(.green)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    // Recent Transactions
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Transactions")
                            .font(.headline)

                        ForEach(viewModel.recentTransactions) { transaction in
                            HStack {
                                Image(systemName: transaction.type == .expense ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                                    .foregroundStyle(transaction.type == .expense ? .red : .green)
                                    .font(.title3)
                                VStack(alignment: .leading) {
                                    Text(transaction.merchantName ?? transaction.category)
                                        .font(.subheadline.bold())
                                    Text(transaction.date, style: .date)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text(transaction.amount, format: .currency(code: "USD"))
                                    .font(.subheadline.bold())
                                    .foregroundStyle(transaction.type == .expense ? .red : .green)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding()
            }
            .navigationTitle("Dashboard")
            .refreshable {
                await viewModel.fetchDashboardData()
            }
            .task {
                await viewModel.fetchDashboardData()
            }
        }
    }
}

#Preview {
    DashboardView()
}

private struct StatTileView: View {
    let title: String
    let value: Double
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.caption)
            }
            .foregroundStyle(color)
            Text(value, format: .currency(code: "USD"))
                .font(.subheadline.bold())
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
