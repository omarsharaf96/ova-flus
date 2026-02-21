import SwiftUI
import SwiftData
import Charts

struct AnalyticsView: View {
    @Query(sort: \TransactionModel.date, order: .reverse) var transactions: [TransactionModel]
    @StateObject private var viewModel = AnalyticsViewModel()

    enum Period: String, CaseIterable {
        case oneMonth = "1M"
        case threeMonths = "3M"
        case sixMonths = "6M"
        case oneYear = "1Y"

        var months: Int {
            switch self {
            case .oneMonth: return 1
            case .threeMonths: return 3
            case .sixMonths: return 6
            case .oneYear: return 12
            }
        }
    }

    @State private var selectedPeriod: Period = .threeMonths
    private let monthFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM"
        return f
    }()

    var categoryData: [AnalyticsViewModel.CategoryTotal] {
        viewModel.categoryTotals(from: transactions, type: "expense")
    }

    var incomeExpenseData: [AnalyticsViewModel.MonthlyIncomeExpense] {
        viewModel.monthlyIncomeExpense(from: transactions, months: selectedPeriod.months)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Period Picker
                    Picker("Period", selection: $selectedPeriod) {
                        ForEach(Period.allCases, id: \.self) { period in
                            Text(period.rawValue).tag(period)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    // Spending by Category — Donut Chart
                    if !categoryData.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Spending by Category")
                                .font(.headline)
                                .padding(.horizontal)
                            Chart(categoryData) { item in
                                SectorMark(
                                    angle: .value("Amount", item.total),
                                    innerRadius: .ratio(0.5)
                                )
                                .foregroundStyle(by: .value("Category", item.category))
                            }
                            .frame(height: 220)
                            .padding(.horizontal)
                        }
                        .padding(.vertical, 12)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }

                    // Income vs Expense — Grouped Bar Chart
                    if !incomeExpenseData.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Income vs Expense")
                                .font(.headline)
                                .padding(.horizontal)
                            Chart {
                                ForEach(incomeExpenseData) { item in
                                    BarMark(
                                        x: .value("Month", monthFormatter.string(from: item.month)),
                                        y: .value("Amount", item.income)
                                    )
                                    .foregroundStyle(by: .value("Type", "Income"))
                                    .position(by: .value("Type", "Income"))

                                    BarMark(
                                        x: .value("Month", monthFormatter.string(from: item.month)),
                                        y: .value("Amount", item.expense)
                                    )
                                    .foregroundStyle(by: .value("Type", "Expense"))
                                    .position(by: .value("Type", "Expense"))
                                }
                            }
                            .frame(height: 200)
                            .padding(.horizontal)
                            .chartForegroundStyleScale([
                                "Income": Color.green,
                                "Expense": Color.red
                            ])
                        }
                        .padding(.vertical, 12)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }

                    // Net Savings Trend — Line Chart
                    if !incomeExpenseData.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Net Savings Trend")
                                .font(.headline)
                                .padding(.horizontal)
                            Chart(incomeExpenseData) { item in
                                LineMark(
                                    x: .value("Month", monthFormatter.string(from: item.month)),
                                    y: .value("Net Savings", item.netSavings)
                                )
                                .foregroundStyle(Color.accentColor)
                                .interpolationMethod(.catmullRom)

                                PointMark(
                                    x: .value("Month", monthFormatter.string(from: item.month)),
                                    y: .value("Net Savings", item.netSavings)
                                )
                                .foregroundStyle(Color.accentColor)
                            }
                            .frame(height: 180)
                            .padding(.horizontal)
                        }
                        .padding(.vertical, 12)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }

                    // Category Breakdown — Horizontal Bar Chart
                    if !categoryData.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Category Breakdown")
                                .font(.headline)
                                .padding(.horizontal)
                            Chart(categoryData) { item in
                                BarMark(
                                    x: .value("Amount", item.total),
                                    y: .value("Category", item.category)
                                )
                                .foregroundStyle(by: .value("Category", item.category))
                                .annotation(position: .trailing) {
                                    Text("$\(item.total, specifier: "%.0f")")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .frame(height: CGFloat(max(200, categoryData.count * 40)))
                            .padding(.horizontal)
                        }
                        .padding(.vertical, 12)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }

                    // Empty state
                    if categoryData.isEmpty && incomeExpenseData.isEmpty {
                        ContentUnavailableView(
                            "No Data Yet",
                            systemImage: "chart.xyaxis.line",
                            description: Text("Add transactions to see your spending analytics")
                        )
                        .padding(.top, 40)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Analytics")
        }
    }
}
