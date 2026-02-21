import SwiftData
import Foundation

@Model
final class BudgetModel {
    var id: String
    var name: String
    var category: String
    var amount: Double
    var spent: Double
    var period: String // "weekly", "biweekly", "monthly", "yearly"
    var startDate: Date
    var endDate: Date
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade) var transactions: [TransactionModel] = []

    init(id: String = UUID().uuidString, name: String, category: String, amount: Double, spent: Double = 0, period: String, startDate: Date, endDate: Date, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.name = name
        self.category = category
        self.amount = amount
        self.spent = spent
        self.period = period
        self.startDate = startDate
        self.endDate = endDate
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var progress: Double {
        guard amount > 0 else { return 0 }
        return min(spent / amount, 1.0)
    }

    var remaining: Double {
        max(amount - spent, 0)
    }

    var categoryIcon: String {
        switch category.lowercased() {
        case "food", "groceries": return "🛒"
        case "transport", "transportation": return "🚗"
        case "shopping": return "🛍️"
        case "entertainment": return "🎬"
        case "bills", "utilities": return "💡"
        case "health", "healthcare": return "💊"
        case "travel": return "✈️"
        case "education": return "📚"
        case "savings": return "💰"
        default: return "💳"
        }
    }
}

@Model
final class TransactionModel {
    var id: String
    var amount: Double
    var type: String // "expense", "income", "transfer"
    var category: String
    var merchantName: String?
    var notes: String?
    var date: Date
    var budgetId: String?
    var plaidTransactionId: String? // nil for manual entries
    var isRecurring: Bool
    var recurringFrequency: String? // "Weekly", "Bi-weekly", "Monthly", "Yearly"

    var budget: BudgetModel?

    init(id: String = UUID().uuidString, amount: Double, type: String, category: String, merchantName: String? = nil, notes: String? = nil, date: Date = Date(), budgetId: String? = nil, budget: BudgetModel? = nil, plaidTransactionId: String? = nil, isRecurring: Bool = false, recurringFrequency: String? = nil) {
        self.id = id
        self.amount = amount
        self.type = type
        self.category = category
        self.merchantName = merchantName
        self.notes = notes
        self.date = date
        self.budgetId = budgetId
        self.budget = budget
        self.plaidTransactionId = plaidTransactionId
        self.isRecurring = isRecurring
        self.recurringFrequency = recurringFrequency
    }
}

@Model
final class HoldingModel {
    var id: String
    var symbol: String
    var companyName: String
    var shares: Double
    var averageCost: Double
    var purchaseDate: Date

    init(id: String = UUID().uuidString, symbol: String, companyName: String, shares: Double, averageCost: Double, purchaseDate: Date = Date()) {
        self.id = id
        self.symbol = symbol
        self.companyName = companyName
        self.shares = shares
        self.averageCost = averageCost
        self.purchaseDate = purchaseDate
    }

    var totalCost: Double {
        shares * averageCost
    }
}

@Model
final class GoalModel {
    var id: String
    var name: String
    var targetAmount: Double
    var currentAmount: Double
    var deadline: Date?
    var category: String // "savings", "debt_payoff", "emergency_fund", "investment", "custom"
    var iconName: String
    var colorHex: String
    var isCompleted: Bool
    var createdAt: Date

    init(id: String = UUID().uuidString, name: String, targetAmount: Double, currentAmount: Double = 0, deadline: Date? = nil, category: String, iconName: String, colorHex: String, isCompleted: Bool = false, createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.targetAmount = targetAmount
        self.currentAmount = currentAmount
        self.deadline = deadline
        self.category = category
        self.iconName = iconName
        self.colorHex = colorHex
        self.isCompleted = isCompleted
        self.createdAt = createdAt
    }

    var progress: Double {
        guard targetAmount > 0 else { return 0 }
        return min(currentAmount / targetAmount, 1.0)
    }

    var remaining: Double {
        max(targetAmount - currentAmount, 0)
    }

    var daysRemaining: Int? {
        guard let deadline else { return nil }
        return Calendar.current.dateComponents([.day], from: Date(), to: deadline).day
    }
}

@Model
final class WatchlistItemModel {
    var id: String
    var symbol: String
    var addedAt: Date

    init(id: String = UUID().uuidString, symbol: String, addedAt: Date = Date()) {
        self.id = id
        self.symbol = symbol
        self.addedAt = addedAt
    }
}

@Model
final class LinkedBankAccountModel {
    var id: String          // Plaid item_id
    var institutionId: String
    var institutionName: String
    var accountName: String
    var accountType: String  // "checking", "savings", "credit", etc.
    var mask: String         // last 4 digits
    var linkedAt: Date
    var lastSyncedAt: Date?

    init(id: String, institutionId: String, institutionName: String,
         accountName: String, accountType: String, mask: String,
         linkedAt: Date = Date(), lastSyncedAt: Date? = nil) {
        self.id = id
        self.institutionId = institutionId
        self.institutionName = institutionName
        self.accountName = accountName
        self.accountType = accountType
        self.mask = mask
        self.linkedAt = linkedAt
        self.lastSyncedAt = lastSyncedAt
    }
}
