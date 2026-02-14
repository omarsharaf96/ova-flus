import Foundation

struct Transaction: Identifiable, Codable, Hashable {
    let id: String
    let merchant: String
    let amount: Double
    let category: String
    let date: Date
    let type: TransactionType
    let notes: String?
    let receiptURL: String?
    let budgetId: String?
    let createdAt: Date
    let updatedAt: Date

    enum TransactionType: String, Codable {
        case expense
        case income
        case transfer
    }
}
