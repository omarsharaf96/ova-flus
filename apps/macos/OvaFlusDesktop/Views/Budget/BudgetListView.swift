import SwiftUI

struct BudgetListView: View {
    @State private var budgets: [Budget] = []
    @State private var selectedBudget: Budget?
    @State private var showingAddSheet = false

    var body: some View {
        VStack {
            // Toolbar
            HStack {
                Text("Budgets")
                    .font(.title2.weight(.bold))
                Spacer()
                Button {
                    showingAddSheet = true
                } label: {
                    Label("Add Budget", systemImage: "plus")
                }
            }
            .padding(.horizontal)
            .padding(.top)

            // Budget table
            Table(budgets, selection: $selectedBudget) {
                TableColumn("Name") { budget in
                    Text(budget.name)
                        .fontWeight(.medium)
                }
                .width(min: 120, ideal: 180)

                TableColumn("Spent") { budget in
                    Text("$\(budget.spent, specifier: "%.2f")")
                }
                .width(min: 80, ideal: 100)

                TableColumn("Limit") { budget in
                    Text("$\(budget.limit, specifier: "%.2f")")
                }
                .width(min: 80, ideal: 100)

                TableColumn("Remaining") { budget in
                    let remaining = budget.limit - budget.spent
                    Text("$\(remaining, specifier: "%.2f")")
                        .foregroundStyle(remaining < 0 ? .red : .primary)
                }
                .width(min: 80, ideal: 100)

                TableColumn("% Used") { budget in
                    let percent = budget.limit > 0 ? (budget.spent / budget.limit * 100) : 0
                    HStack(spacing: 8) {
                        ProgressView(value: min(percent / 100, 1.0))
                            .frame(width: 60)
                            .tint(percent > 90 ? .red : percent > 70 ? .orange : .green)
                        Text("\(percent, specifier: "%.0f")%")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .width(min: 100, ideal: 140)
            }
        }
        .sheet(item: $selectedBudget) { budget in
            BudgetDetailView(budget: budget)
                .frame(minWidth: 500, minHeight: 400)
        }
        .navigationTitle("Budgets")
    }
}
