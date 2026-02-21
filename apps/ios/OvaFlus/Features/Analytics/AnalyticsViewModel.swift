import Foundation
import SwiftData

@MainActor
class AnalyticsViewModel: ObservableObject {

    struct MonthlySpendingData: Identifiable {
        let id = UUID()
        let month: Date
        let category: String
        let amount: Double
    }

    struct MonthlyIncomeExpense: Identifiable {
        let id = UUID()
        let month: Date
        let income: Double
        let expense: Double
        var netSavings: Double { income - expense }
    }

    struct CategoryTotal: Identifiable {
        let id = UUID()
        let category: String
        let total: Double
        let percentage: Double
    }

    private func startOfMonth(for date: Date) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: date)
        return calendar.date(from: components) ?? date
    }

    func monthlySpending(from transactions: [TransactionModel], months: Int = 6) -> [MonthlySpendingData] {
        let cutoff = Calendar.current.date(byAdding: .month, value: -months, to: Date()) ?? Date()
        let filtered = transactions.filter { $0.type == "expense" && $0.date >= cutoff }

        var grouped: [String: [TransactionModel]] = [:]
        for txn in filtered {
            let key = "\(startOfMonth(for: txn.date).timeIntervalSince1970)-\(txn.category)"
            grouped[key, default: []].append(txn)
        }

        return grouped.map { key, txns in
            let parts = key.split(separator: "-", maxSplits: 1)
            let monthDate = Date(timeIntervalSince1970: Double(parts[0]) ?? 0)
            return MonthlySpendingData(
                month: monthDate,
                category: txns[0].category,
                amount: txns.reduce(0) { $0 + $1.amount }
            )
        }.sorted { $0.month < $1.month }
    }

    func monthlyIncomeExpense(from transactions: [TransactionModel], months: Int = 6) -> [MonthlyIncomeExpense] {
        let cutoff = Calendar.current.date(byAdding: .month, value: -months, to: Date()) ?? Date()
        let filtered = transactions.filter { $0.date >= cutoff }

        var monthlyData: [Date: (income: Double, expense: Double)] = [:]
        for txn in filtered {
            let month = startOfMonth(for: txn.date)
            var data = monthlyData[month] ?? (income: 0, expense: 0)
            if txn.type == "income" {
                data.income += txn.amount
            } else if txn.type == "expense" {
                data.expense += txn.amount
            }
            monthlyData[month] = data
        }

        return monthlyData.map { month, data in
            MonthlyIncomeExpense(month: month, income: data.income, expense: data.expense)
        }.sorted { $0.month < $1.month }
    }

    func categoryTotals(from transactions: [TransactionModel], type: String = "expense") -> [CategoryTotal] {
        let filtered = transactions.filter { $0.type == type }
        let grandTotal = filtered.reduce(0) { $0 + $1.amount }
        guard grandTotal > 0 else { return [] }

        var categoryAmounts: [String: Double] = [:]
        for txn in filtered {
            categoryAmounts[txn.category, default: 0] += txn.amount
        }

        return categoryAmounts.map { category, total in
            CategoryTotal(category: category, total: total, percentage: (total / grandTotal) * 100)
        }.sorted { $0.total > $1.total }
    }
}
