import SwiftUI
import Charts

struct BudgetDetailView: View {
    let budget: Budget
    @State private var categoryBreakdown: [CategorySpending] = []
    @State private var alertThreshold: Double = 80.0
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text(budget.name)
                        .font(.title2.weight(.bold))
                    Text("$\(budget.spent, specifier: "%.2f") of $\(budget.limit, specifier: "%.2f")")
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Done") { dismiss() }
            }
            .padding()

            Divider()

            ScrollView {
                VStack(spacing: 20) {
                    // Category spending bar chart
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Spending by Category")
                            .font(.headline)

                        Chart(categoryBreakdown) { item in
                            BarMark(
                                x: .value("Amount", item.amount),
                                y: .value("Category", item.name)
                            )
                            .foregroundStyle(by: .value("Category", item.name))
                        }
                        .frame(height: CGFloat(max(categoryBreakdown.count * 40, 120)))
                    }

                    Divider()

                    // Category breakdown table
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Category Details")
                            .font(.headline)

                        Table(categoryBreakdown) {
                            TableColumn("Category") { item in
                                Text(item.name)
                            }
                            TableColumn("Amount") { item in
                                Text("$\(item.amount, specifier: "%.2f")")
                            }
                            TableColumn("% of Budget") { item in
                                let percent = budget.limit > 0 ? (item.amount / budget.limit * 100) : 0
                                Text("\(percent, specifier: "%.1f")%")
                            }
                        }
                        .frame(height: 200)
                    }

                    Divider()

                    // Alert threshold settings
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Alert Threshold")
                            .font(.headline)
                        HStack {
                            Slider(value: $alertThreshold, in: 50...100, step: 5)
                            Text("\(alertThreshold, specifier: "%.0f")%")
                                .frame(width: 40)
                        }
                        Text("Get notified when spending reaches \(alertThreshold, specifier: "%.0f")% of budget limit.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
            }
        }
    }
}

struct CategorySpending: Identifiable {
    let id = UUID()
    let name: String
    let amount: Double
}
