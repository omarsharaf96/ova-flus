import Foundation

enum TransactionType: String, Codable {
    case expense
    case income
    case transfer
}

struct Transaction: Codable, Identifiable {
    let id: String
    var amount: Double
    var type: TransactionType
    var category: String
    var date: Date
    var merchantName: String?
    var notes: String?
    var receiptURL: String?
    var budgetId: String?
    var isRecurring: Bool?
    var recurringDetails: RecurringTransaction?
}

struct RecurringTransaction: Codable {
    let frequency: RecurringFrequency
    let startDate: Date
    var endDate: Date?
    var isActive: Bool

    enum RecurringFrequency: String, Codable {
        case daily
        case weekly
        case biweekly
        case monthly
        case yearly
    }
}
