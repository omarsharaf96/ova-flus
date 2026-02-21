import Foundation
import SwiftData

@MainActor
class DataMigrationService {
    static let shared = DataMigrationService()

    private let migrationKey = "swiftdata_migration_v1_complete"

    private init() {}

    func migrateIfNeeded(modelContext: ModelContext) {
        guard !UserDefaults.standard.bool(forKey: migrationKey) else { return }

        // Migration from LocalDataManager caches to SwiftData
        // Attempt to load any cached budgets
        if let cachedBudgets: [Budget] = LocalDataManager.shared.loadCachedObject(filename: "budgets_cache.json") {
            for budget in cachedBudgets {
                let model = BudgetModel(
                    id: budget.id,
                    name: budget.name,
                    category: budget.category,
                    amount: budget.amount,
                    spent: budget.spent,
                    period: budget.period.rawValue,
                    startDate: budget.startDate,
                    endDate: budget.endDate,
                    createdAt: budget.createdAt,
                    updatedAt: budget.updatedAt
                )
                modelContext.insert(model)
            }
        }

        // Attempt to load any cached transactions
        if let cachedTransactions: [Transaction] = LocalDataManager.shared.loadCachedObject(filename: "transactions_cache.json") {
            for transaction in cachedTransactions {
                let model = TransactionModel(
                    id: transaction.id,
                    amount: transaction.amount,
                    type: transaction.type.rawValue,
                    category: transaction.category,
                    merchantName: transaction.merchantName,
                    notes: transaction.notes,
                    date: transaction.date,
                    budgetId: transaction.budgetId
                )
                modelContext.insert(model)
            }
        }

        try? modelContext.save()
        UserDefaults.standard.set(true, forKey: migrationKey)
    }
}
