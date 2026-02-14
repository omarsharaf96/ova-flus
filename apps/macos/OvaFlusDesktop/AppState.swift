import Foundation
import Combine

final class AppState: ObservableObject {
    @Published var selectedPortfolioId: String?
    @Published var netWorth: Double = 0.0
    @Published var dayChange: Double = 0.0
    @Published var dayChangePercent: Double = 0.0
    @Published var monthlyBudgetSpent: Double = 0.0
    @Published var monthlyBudgetLimit: Double = 0.0
    @Published var portfolioTotalValue: Double = 0.0

    var budgetRemainingPercent: Double {
        guard monthlyBudgetLimit > 0 else { return 0 }
        return max(0, (monthlyBudgetLimit - monthlyBudgetSpent) / monthlyBudgetLimit * 100)
    }

    var dayChangeFormatted: String {
        let sign = dayChange >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.2f", dayChange)) (\(sign)\(String(format: "%.2f", dayChangePercent))%)"
    }

    func refresh() async {
        // TODO: Fetch latest data from API
    }
}
