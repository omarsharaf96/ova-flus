import Foundation

struct Budget: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let category: String
    let limit: Double
    var spent: Double
    let period: BudgetPeriod
    let startDate: Date
    let endDate: Date
    let createdAt: Date
    let updatedAt: Date

    var remaining: Double { limit - spent }
    var percentUsed: Double { limit > 0 ? spent / limit * 100 : 0 }
    var isOverBudget: Bool { spent > limit }

    enum BudgetPeriod: String, Codable {
        case weekly
        case monthly
        case yearly
    }
}
