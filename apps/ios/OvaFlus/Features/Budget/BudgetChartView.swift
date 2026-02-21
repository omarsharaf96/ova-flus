import Charts
import SwiftData
import SwiftUI

struct BudgetChartView: View {
    @Query(sort: \TransactionModel.date, order: .reverse) private var transactions: [TransactionModel]

    @State private var selectedMonth: Date = {
        let c = Calendar.current
        return c.date(from: c.dateComponents([.year, .month], from: Date()))!
    }()

    private var calendar: Calendar { .current }

    private var monthTransactions: [TransactionModel] {
        let comps = calendar.dateComponents([.year, .month], from: selectedMonth)
        return transactions.filter {
            $0.type == "expense" &&
            calendar.dateComponents([.year, .month], from: $0.date) == comps
        }
    }

    // Daily spending data points
    private var dailySpend: [(day: Date, amount: Double)] {
        let grouped = Dictionary(grouping: monthTransactions) {
            calendar.startOfDay(for: $0.date)
        }
        return grouped
            .map { (day: $0.key, amount: $0.value.reduce(0) { $0 + $1.amount }) }
            .sorted { $0.day < $1.day }
    }

    // Running cumulative total
    private var cumulativeSpend: [(day: Date, total: Double)] {
        var running = 0.0
        return dailySpend.map {
            running += $0.amount
            return (day: $0.day, total: running)
        }
    }

    private var totalMonthSpend: Double { dailySpend.reduce(0) { $0 + $1.amount } }
    private var highestDay: (day: Date, amount: Double)? { dailySpend.max(by: { $0.amount < $1.amount }) }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Month picker
                HStack {
                    Button {
                        selectedMonth = calendar.date(byAdding: .month, value: -1, to: selectedMonth)!
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                    Spacer()
                    Text(selectedMonth, format: .dateTime.month(.wide).year())
                        .font(.headline)
                    Spacer()
                    Button {
                        let next = calendar.date(byAdding: .month, value: 1, to: selectedMonth)!
                        if next <= Date() { selectedMonth = next }
                    } label: {
                        Image(systemName: "chevron.right")
                    }
                }
                .padding(.horizontal)

                // Summary stats
                HStack(spacing: 0) {
                    StatCell(label: "Total Spent", value: totalMonthSpend, color: .red)
                    Divider().frame(height: 44)
                    StatCell(label: "Days Tracked", value: Double(dailySpend.count), isCount: true, color: .blue)
                    Divider().frame(height: 44)
                    if let top = highestDay {
                        StatCell(label: "Highest Day", value: top.amount, color: .orange)
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal)

                // Daily spend bar chart
                VStack(alignment: .leading, spacing: 8) {
                    Text("Daily Spending")
                        .font(.headline)
                        .padding(.horizontal)

                    if dailySpend.isEmpty {
                        ContentUnavailableView(
                            "No Expenses",
                            systemImage: "chart.bar",
                            description: Text("No expense transactions recorded this month.")
                        )
                        .frame(height: 200)
                    } else {
                        Chart(dailySpend, id: \.day) { item in
                            BarMark(
                                x: .value("Day", item.day, unit: .day),
                                y: .value("Amount", item.amount)
                            )
                            .foregroundStyle(.red.opacity(0.8))
                            .cornerRadius(4)
                        }
                        .chartXAxis {
                            AxisMarks(values: .stride(by: .day, count: 7)) {
                                AxisValueLabel(format: .dateTime.day())
                            }
                        }
                        .chartYAxis {
                            AxisMarks { value in
                                AxisValueLabel {
                                    if let v = value.as(Double.self) {
                                        Text(v, format: .currency(code: "USD").precision(.fractionLength(0)))
                                            .font(.caption2)
                                    }
                                }
                                AxisGridLine()
                            }
                        }
                        .frame(height: 200)
                        .padding(.horizontal)
                    }
                }

                // Cumulative line chart
                VStack(alignment: .leading, spacing: 8) {
                    Text("Cumulative Spending")
                        .font(.headline)
                        .padding(.horizontal)

                    if cumulativeSpend.isEmpty {
                        ContentUnavailableView(
                            "No Data",
                            systemImage: "chart.line.uptrend.xyaxis",
                            description: Text("Add expenses to see your spending curve.")
                        )
                        .frame(height: 200)
                    } else {
                        Chart(cumulativeSpend, id: \.day) { item in
                            LineMark(
                                x: .value("Day", item.day, unit: .day),
                                y: .value("Total", item.total)
                            )
                            .foregroundStyle(.blue)
                            .interpolationMethod(.catmullRom)

                            AreaMark(
                                x: .value("Day", item.day, unit: .day),
                                y: .value("Total", item.total)
                            )
                            .foregroundStyle(.blue.opacity(0.1))
                            .interpolationMethod(.catmullRom)
                        }
                        .chartXAxis {
                            AxisMarks(values: .stride(by: .day, count: 7)) {
                                AxisValueLabel(format: .dateTime.day())
                            }
                        }
                        .chartYAxis {
                            AxisMarks { value in
                                AxisValueLabel {
                                    if let v = value.as(Double.self) {
                                        Text(v, format: .currency(code: "USD").precision(.fractionLength(0)))
                                            .font(.caption2)
                                    }
                                }
                                AxisGridLine()
                            }
                        }
                        .frame(height: 200)
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
    }
}

private struct StatCell: View {
    let label: String
    let value: Double
    var isCount = false
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            if isCount {
                Text("\(Int(value))")
                    .font(.title3.bold())
                    .foregroundStyle(color)
            } else {
                Text(value, format: .currency(code: "USD").precision(.fractionLength(0)))
                    .font(.title3.bold())
                    .foregroundStyle(color)
            }
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    BudgetChartView()
        .modelContainer(for: TransactionModel.self, inMemory: true)
}
