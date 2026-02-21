import Foundation

struct CategoryBreakdown: Identifiable {
    let id = UUID()
    let category: String
    let spent: Double
    let budgeted: Double
}

struct BudgetSummaryData {
    let totalBudget: Double
    let totalSpent: Double
    let categoryBreakdown: [CategoryBreakdown]
}

@MainActor
class DashboardViewModel: ObservableObject {
    @Published var budgetSummary: BudgetSummaryData?
    @Published var portfolioValue: Double = 0
    @Published var portfolioDayChange: Double = 0
    @Published var recentTransactions: [Transaction] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let apiClient = APIClient.shared

    func fetchDashboardData() async {
        isLoading = true
        errorMessage = nil

        async let budgetTask: () = fetchBudgetSummary()
        async let portfolioTask: () = fetchPortfolioData()
        async let transactionsTask: () = fetchRecentTransactions()

        await budgetTask
        await portfolioTask
        await transactionsTask

        isLoading = false
    }

    private func fetchBudgetSummary() async {
        do {
            let summaries: [BudgetSummary] = try await apiClient.request(.getBudgets)
            let totalBudget = summaries.reduce(0) { $0 + $1.totalBudget }
            let totalSpent = summaries.reduce(0) { $0 + $1.totalSpent }
            let breakdown = summaries.map {
                CategoryBreakdown(category: $0.category, spent: $0.totalSpent, budgeted: $0.totalBudget)
            }
            budgetSummary = BudgetSummaryData(
                totalBudget: totalBudget,
                totalSpent: totalSpent,
                categoryBreakdown: breakdown
            )
        } catch {
            errorMessage = "Failed to load budget data"
        }
    }

    private func fetchPortfolioData() async {
        do {
            let portfolio: Portfolio = try await apiClient.request(.getPortfolio)
            portfolioValue = portfolio.totalValue
            portfolioDayChange = portfolio.dayChange
        } catch {
            errorMessage = "Failed to load portfolio data"
        }
    }

    private func fetchRecentTransactions() async {
        do {
            let transactions: [Transaction] = try await apiClient.request(.getRecentTransactions)
            recentTransactions = transactions
        } catch {
            errorMessage = "Failed to load transactions"
        }
    }
}
