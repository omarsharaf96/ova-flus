import Foundation

@MainActor
class BudgetViewModel: ObservableObject {

    func budgetSummary(from budgets: [BudgetModel]) -> BudgetSummaryData {
        let totalBudget = budgets.reduce(0) { $0 + $1.amount }
        let totalSpent = budgets.reduce(0) { $0 + $1.spent }
        let breakdown = categoryBreakdown(from: budgets)
        return BudgetSummaryData(totalBudget: totalBudget, totalSpent: totalSpent, categoryBreakdown: breakdown)
    }

    func categoryBreakdown(from budgets: [BudgetModel]) -> [CategoryBreakdown] {
        Dictionary(grouping: budgets, by: { $0.category })
            .map { category, budgets in
                CategoryBreakdown(
                    category: category,
                    spent: budgets.reduce(0) { $0 + $1.spent },
                    budgeted: budgets.reduce(0) { $0 + $1.amount }
                )
            }
            .sorted { $0.spent > $1.spent }
    }
}
