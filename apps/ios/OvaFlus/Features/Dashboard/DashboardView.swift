import SwiftUI
import Charts

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Portfolio Value Card
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Portfolio Value")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(viewModel.portfolioValue, format: .currency(code: "USD"))
                            .font(.system(size: 34, weight: .bold))
                        HStack {
                            Image(systemName: viewModel.portfolioDayChange >= 0 ? "arrow.up.right" : "arrow.down.right")
                            Text(viewModel.portfolioDayChange, format: .currency(code: "USD"))
                            Text("today")
                                .foregroundStyle(.secondary)
                        }
                        .font(.subheadline)
                        .foregroundStyle(viewModel.portfolioDayChange >= 0 ? .green : .red)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

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
