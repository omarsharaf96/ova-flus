import SwiftUI

struct BudgetListView: View {
    @StateObject private var viewModel = BudgetViewModel()
    @State private var showAddBudget = false

    var body: some View {
        NavigationStack {
            List {
                // Overall progress section
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Total Budget")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(viewModel.totalSpent, format: .currency(code: "USD")) / \(viewModel.totalBudget, format: .currency(code: "USD"))")
                                .font(.subheadline.bold())
                        }
                        ProgressView(value: viewModel.totalBudget > 0 ? viewModel.totalSpent / viewModel.totalBudget : 0)
                            .tint(viewModel.totalSpent > viewModel.totalBudget ? .red : .blue)
                    }
                    .padding(.vertical, 4)
                }

                // Category breakdown
                Section("Categories") {
                    ForEach(viewModel.budgets) { budget in
                        NavigationLink {
                            BudgetDetailView(budget: budget)
                        } label: {
                            BudgetRowView(budget: budget)
                        }
                    }
                }
            }
            .navigationTitle("Budget")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAddBudget = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddBudget) {
                AddTransactionView()
            }
            .refreshable {
                await viewModel.fetchBudgets()
            }
            .task {
                await viewModel.fetchBudgets()
            }
        }
    }
}

struct BudgetRowView: View {
    let budget: Budget

    private var progress: Double {
        guard budget.amount > 0 else { return 0 }
        return budget.spent / budget.amount
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(budget.category, systemImage: budget.categoryIcon)
                    .font(.subheadline.bold())
                Spacer()
                Text(budget.amount - budget.spent, format: .currency(code: "USD"))
                    .font(.subheadline)
                    .foregroundStyle(budget.spent > budget.amount ? .red : .green)
            }
            ProgressView(value: min(progress, 1.0))
                .tint(progress > 0.9 ? .red : progress > 0.7 ? .orange : .blue)
            HStack {
                Text("\(budget.spent, format: .currency(code: "USD")) spent")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(budget.amount, format: .currency(code: "USD")) budgeted")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    BudgetListView()
}
