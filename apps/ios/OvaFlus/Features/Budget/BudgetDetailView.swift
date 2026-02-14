import SwiftUI
import Charts

struct BudgetDetailView: View {
    let budget: Budget
    @StateObject private var viewModel = BudgetViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Budget progress card
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 12)
                        Circle()
                            .trim(from: 0, to: min(budget.spent / budget.amount, 1.0))
                            .stroke(
                                budget.spent > budget.amount ? Color.red : Color.blue,
                                style: StrokeStyle(lineWidth: 12, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                        VStack {
                            Text(budget.spent, format: .currency(code: "USD"))
                                .font(.title2.bold())
                            Text("of \(budget.amount, format: .currency(code: "USD"))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(height: 180)
                    .padding()

                    HStack(spacing: 24) {
                        VStack {
                            Text("Spent")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(budget.spent, format: .currency(code: "USD"))
                                .font(.subheadline.bold())
                                .foregroundStyle(.red)
                        }
                        VStack {
                            Text("Remaining")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(max(budget.amount - budget.spent, 0), format: .currency(code: "USD"))
                                .font(.subheadline.bold())
                                .foregroundStyle(.green)
                        }
                        VStack {
                            Text("Daily Avg")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(budget.spent / 30, format: .currency(code: "USD"))
                                .font(.subheadline.bold())
                        }
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                // Transactions list
                VStack(alignment: .leading, spacing: 12) {
                    Text("Transactions")
                        .font(.headline)

                    ForEach(viewModel.transactions) { transaction in
                        HStack {
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
                        Divider()
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding()
        }
        .navigationTitle(budget.category)
        .task {
            await viewModel.fetchTransactions(for: budget.id)
        }
    }
}
