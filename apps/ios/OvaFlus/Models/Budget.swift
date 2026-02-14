import Foundation

struct Budget: Codable, Identifiable {
    let id: String
    var name: String
    var category: String
    var amount: Double
    var spent: Double
    var period: BudgetPeriod
    var startDate: Date
    var endDate: Date
    var createdAt: Date
    var updatedAt: Date

    var categoryIcon: String {
        switch category.lowercased() {
        case "food & dining": return "fork.knife"
        case "transportation": return "car.fill"
        case "shopping": return "bag.fill"
        case "entertainment": return "film.fill"
        case "bills & utilities": return "bolt.fill"
        case "health & fitness": return "heart.fill"
        case "travel": return "airplane"
        case "education": return "book.fill"
        case "personal care": return "sparkles"
        case "gifts & donations": return "gift.fill"
        default: return "dollarsign.circle"
        }
    }

    enum BudgetPeriod: String, Codable {
        case weekly
        case biweekly
        case monthly
        case yearly
    }
}

struct BudgetCategory: Codable, Identifiable {
    let id: String
    var name: String
    var icon: String
    var color: String
}

struct BudgetSummary: Codable {
    let category: String
    let totalBudget: Double
    let totalSpent: Double
    let transactionCount: Int
}
