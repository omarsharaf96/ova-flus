import Foundation

@MainActor
class BudgetViewModel: ObservableObject {
    @Published var budgets: [Budget] = []
    @Published var transactions: [Transaction] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    var totalBudget: Double {
        budgets.reduce(0) { $0 + $1.amount }
    }

    var totalSpent: Double {
        budgets.reduce(0) { $0 + $1.spent }
    }

    private let apiClient = APIClient.shared

    func fetchBudgets() async {
        isLoading = true
        do {
            budgets = try await apiClient.request(.getBudgets)
        } catch {
            errorMessage = "Failed to load budgets"
        }
        isLoading = false
    }

    func fetchTransactions(for budgetId: String) async {
        isLoading = true
        do {
            transactions = try await apiClient.request(.getTransactions(budgetId: budgetId))
        } catch {
            errorMessage = "Failed to load transactions"
        }
        isLoading = false
    }

    func addTransaction(_ transaction: Transaction) async {
        do {
            let _: Transaction = try await apiClient.request(.createTransaction(transaction))
            await fetchBudgets()
        } catch {
            errorMessage = "Failed to save transaction"
        }
    }

    func deleteBudget(_ budget: Budget) async {
        do {
            let _: EmptyResponse = try await apiClient.request(.deleteBudget(id: budget.id))
            budgets.removeAll { $0.id == budget.id }
        } catch {
            errorMessage = "Failed to delete budget"
        }
    }
}

struct EmptyResponse: Decodable {}
