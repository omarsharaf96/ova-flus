import SwiftUI
import SwiftData
import Charts

struct BudgetDetailView: View {
    let budget: BudgetModel
    @State private var filterType: String = "All"
    @State private var searchText: String = ""
    @State private var showAddTransaction = false

    private let filterOptions = ["All", "Expense", "Income"]

    var filteredTransactions: [TransactionModel] {
        budget.transactions
            .filter { filterType == "All" || $0.type == filterType.lowercased() }
            .filter { searchText.isEmpty || ($0.merchantName ?? "").localizedCaseInsensitiveContains(searchText) || $0.category.localizedCaseInsensitiveContains(searchText) }
            .sorted { $0.date > $1.date }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Budget progress card
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 12)
                        Circle()
                            .trim(from: 0, to: budget.progress)
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
                            Text(budget.remaining, format: .currency(code: "USD"))
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

                // Filter
                Picker("Filter", selection: $filterType) {
                    ForEach(filterOptions, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                // Transactions list
                VStack(alignment: .leading, spacing: 12) {
                    Text("Transactions")
                        .font(.headline)

                    if filteredTransactions.isEmpty {
                        Text("No transactions yet")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 20)
                    } else {
                        ForEach(filteredTransactions, id: \.id) { transaction in
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
                                    .foregroundStyle(transaction.type == "expense" ? .red : .green)
                            }
                            .padding(.vertical, 4)
                            Divider()
                        }
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding()
        }
        .navigationTitle(budget.category)
        .searchable(text: $searchText)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showAddTransaction = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddTransaction) {
            AddTransactionView(budget: budget)
        }
    }
}
