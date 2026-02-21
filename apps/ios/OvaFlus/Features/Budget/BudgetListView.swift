import SwiftUI
import SwiftData

private enum BudgetTab: String, CaseIterable {
    case budgets   = "Budgets"
    case chart     = "Chart"
    case recurring = "Recurring"
}

struct BudgetListView: View {
    @Query(sort: \BudgetModel.createdAt, order: .reverse) var budgets: [BudgetModel]
    @Environment(\.modelContext) private var modelContext
    @State private var showAddBudget = false
    @State private var editingBudget: BudgetModel? = nil
    @State private var selectedTab: BudgetTab = .budgets

    private var totalBudget: Double {
        budgets.reduce(0) { $0 + $1.amount }
    }

    private var totalSpent: Double {
        budgets.reduce(0) { $0 + $1.spent }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Segmented picker
                Picker("", selection: $selectedTab) {
                    ForEach(BudgetTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 8)

                // Content
                switch selectedTab {
                case .budgets:
                    budgetsList
                case .chart:
                    BudgetChartView()
                case .recurring:
                    RecurringPaymentsView()
                }
            }
            .navigationTitle("Budget")
            .toolbar {
                if selectedTab == .budgets {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showAddBudget = true
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .sheet(isPresented: $showAddBudget) {
                AddBudgetView()
            }
            .sheet(item: $editingBudget) { budget in
                AddBudgetView(existingBudget: budget)
            }
        }
    }

    private var budgetsList: some View {
        List {
            // Overall progress section
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Total Budget")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(totalSpent, format: .currency(code: "USD")) / \(totalBudget, format: .currency(code: "USD"))")
                            .font(.subheadline.bold())
                    }
                    ProgressView(value: totalBudget > 0 ? totalSpent / totalBudget : 0)
                        .tint(totalSpent > totalBudget ? .red : .blue)
                }
                .padding(.vertical, 4)
            }

            // Category breakdown
            Section("Categories") {
                ForEach(budgets) { budget in
                    NavigationLink {
                        BudgetDetailView(budget: budget)
                    } label: {
                        BudgetRowView(budget: budget)
                    }
                    .swipeActions(edge: .leading) {
                        Button {
                            editingBudget = budget
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .tint(.blue)
                    }
                }
                .onDelete(perform: deleteBudgets)
            }
        }
    }

    private func deleteBudgets(at offsets: IndexSet) {
        for offset in offsets {
            modelContext.delete(budgets[offset])
        }
    }
}

struct BudgetRowView: View {
    let budget: BudgetModel

    private var progress: Double {
        guard budget.amount > 0 else { return 0 }
        return budget.spent / budget.amount
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(budget.categoryIcon) \(budget.category)")
                    .font(.subheadline.bold())
                Spacer()
                Text(budget.remaining, format: .currency(code: "USD"))
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
        .modelContainer(for: BudgetModel.self, inMemory: true)
}
