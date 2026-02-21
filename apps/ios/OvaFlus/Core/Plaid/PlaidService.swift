import Foundation
import SwiftData

// Response models for Plaid API
struct PlaidAccount: Codable {
    let id: String
    let institutionId: String
    let institutionName: String
    let accountName: String
    let accountType: String
    let mask: String
    let linkedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case institutionId = "institution_id"
        case institutionName = "institution_name"
        case accountName = "account_name"
        case accountType = "account_type"
        case mask
        case linkedAt = "linked_at"
    }
}

struct PlaidTransactionDTO: Codable {
    let id: String
    let accountId: String
    let name: String
    let amount: Double
    let date: String
    let category: [String]
    let pending: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case accountId = "account_id"
        case name
        case amount
        case date
        case category
        case pending
    }
}

struct PlaidSyncResponse: Codable {
    let transactions: [PlaidTransactionDTO]
    let added: Int
    let modified: Int
}

struct PlaidLinkTokenResponse: Codable {
    let linkToken: String

    enum CodingKeys: String, CodingKey {
        case linkToken = "link_token"
    }
}

@MainActor
final class PlaidService: ObservableObject {
    static let shared = PlaidService()

    @Published var linkedAccounts: [LinkedBankAccountModel] = []
    @Published var isSyncing = false
    @Published var errorMessage: String?

    private let apiClient = APIClient.shared

    private let categoryMap: [String: String] = [
        "Food and Drink": "Food & Dining",
        "Travel": "Transportation",
        "Shops": "Shopping",
        "Recreation": "Entertainment",
        "Arts and Entertainment": "Entertainment",
        "Service": "Bills & Utilities",
        "Healthcare": "Health & Fitness",
        "Education": "Education",
        "Personal Care": "Personal Care"
    ]

    private init() {}

    // MARK: - Link Token

    func createLinkToken() async throws -> String {
        let response: PlaidLinkTokenResponse = try await apiClient.request(.plaidCreateLinkToken)
        return response.linkToken
    }

    // MARK: - Exchange Public Token

    func exchangePublicToken(
        _ publicToken: String,
        institutionId: String,
        institutionName: String,
        accounts: [[String: String]],
        context: ModelContext
    ) async throws {
        let _: EmptyResponse = try await apiClient.request(
            .plaidExchangeToken(
                publicToken: publicToken,
                institutionId: institutionId,
                institutionName: institutionName,
                accounts: accounts
            )
        )
        await fetchLinkedAccounts(context: context)
    }

    // MARK: - Fetch Linked Accounts

    func fetchLinkedAccounts(context: ModelContext) async {
        do {
            let dtos: [PlaidAccount] = try await apiClient.request(.plaidGetAccounts)

            // Remove stale accounts
            let descriptor = FetchDescriptor<LinkedBankAccountModel>()
            let existing = (try? context.fetch(descriptor)) ?? []
            for account in existing {
                context.delete(account)
            }

            // Insert fresh accounts
            let formatter = ISO8601DateFormatter()
            for dto in dtos {
                let model = LinkedBankAccountModel(
                    id: dto.id,
                    institutionId: dto.institutionId,
                    institutionName: dto.institutionName,
                    accountName: dto.accountName,
                    accountType: dto.accountType,
                    mask: dto.mask,
                    linkedAt: formatter.date(from: dto.linkedAt) ?? Date()
                )
                context.insert(model)
            }

            try? context.save()
            linkedAccounts = (try? context.fetch(FetchDescriptor<LinkedBankAccountModel>())) ?? []
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Sync Transactions

    func syncTransactions(context: ModelContext) async {
        isSyncing = true
        defer { isSyncing = false }

        do {
            let response: PlaidSyncResponse = try await apiClient.request(.plaidSyncTransactions)

            // Fetch existing plaidTransactionIds for dedup
            let txDescriptor = FetchDescriptor<TransactionModel>()
            let existing = (try? context.fetch(txDescriptor)) ?? []
            let existingPlaidIds = Set(existing.compactMap(\.plaidTransactionId))

            // Fetch budgets for category matching
            let budgetDescriptor = FetchDescriptor<BudgetModel>()
            let budgets = (try? context.fetch(budgetDescriptor)) ?? []

            let formatter = ISO8601DateFormatter()
            var affectedBudgets: Set<String> = []

            for dto in response.transactions {
                guard !dto.pending else { continue }
                guard !existingPlaidIds.contains(dto.id) else { continue }

                let primaryCategory = dto.category.first ?? "Other"
                let appCategory = categoryMap[primaryCategory] ?? primaryCategory
                let matchedBudget = matchBudget(for: appCategory, budgets: budgets)

                // Plaid: positive amount = money spent, negative = income
                let txType = dto.amount > 0 ? "expense" : "income"
                let absAmount = abs(dto.amount)

                let transaction = TransactionModel(
                    amount: absAmount,
                    type: txType,
                    category: appCategory,
                    merchantName: dto.name,
                    date: formatter.date(from: dto.date) ?? Date(),
                    budgetId: matchedBudget?.id,
                    budget: matchedBudget,
                    plaidTransactionId: dto.id
                )
                context.insert(transaction)

                if let budget = matchedBudget, txType == "expense" {
                    budget.spent += absAmount
                    budget.updatedAt = Date()
                    affectedBudgets.insert(budget.id)
                }
            }

            try? context.save()

            // Update lastSyncedAt for linked accounts
            let accountDescriptor = FetchDescriptor<LinkedBankAccountModel>()
            let accounts = (try? context.fetch(accountDescriptor)) ?? []
            for account in accounts {
                account.lastSyncedAt = Date()
            }
            try? context.save()
            linkedAccounts = accounts

            // Trigger budget alerts for affected budgets
            let affectedBudgetModels = budgets.filter { affectedBudgets.contains($0.id) }
            for budget in affectedBudgetModels {
                NotificationService.shared.checkBudgetAlert(budget: budget)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Unlink Account

    func unlinkAccount(_ account: LinkedBankAccountModel, context: ModelContext) async {
        do {
            let _: EmptyResponse = try await apiClient.request(.plaidUnlinkAccount(itemId: account.id))
            context.delete(account)
            try? context.save()
            linkedAccounts.removeAll { $0.id == account.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Private

    private func matchBudget(for category: String, budgets: [BudgetModel]) -> BudgetModel? {
        budgets.first { budget in
            budget.category.lowercased() == category.lowercased() ||
            budget.name.lowercased().contains(category.lowercased())
        }
    }
}

// Minimal decodable for endpoints that return empty body / status only
private struct EmptyResponse: Codable {}
