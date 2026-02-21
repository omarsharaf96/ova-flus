import SwiftData
import SwiftUI

struct RecurringPaymentsView: View {
    @Query(sort: \TransactionModel.date, order: .reverse) private var transactions: [TransactionModel]

    // Group expenses by merchant/category and keep only those appearing 2+ times
    private var recurringGroups: [RecurringGroup] {
        let expenses = transactions.filter { $0.type == "expense" }
        let key: (TransactionModel) -> String = { $0.merchantName ?? $0.category }
        let grouped = Dictionary(grouping: expenses, by: key)

        return grouped
            .filter { $0.value.count >= 2 }
            .map { name, txns in
                let sorted = txns.sorted { $0.date > $1.date }
                let avg = txns.reduce(0) { $0 + $1.amount } / Double(txns.count)
                let frequency = estimatedFrequency(txns.map(\.date))
                return RecurringGroup(
                    name: name,
                    category: sorted.first?.category ?? "",
                    occurrences: txns.count,
                    averageAmount: avg,
                    lastDate: sorted.first?.date ?? Date(),
                    frequency: frequency
                )
            }
            .sorted { $0.averageAmount > $1.averageAmount }
    }

    private var totalMonthlyEstimate: Double {
        recurringGroups.reduce(0) { $0 + $1.monthlyEstimate }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Summary banner
                VStack(spacing: 4) {
                    Text("Est. Monthly Recurring")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(totalMonthlyEstimate, format: .currency(code: "USD"))
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(.red)
                    Text("\(recurringGroups.count) recurring payments detected")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal)

                if recurringGroups.isEmpty {
                    ContentUnavailableView(
                        "No Recurring Payments",
                        systemImage: "arrow.clockwise.circle",
                        description: Text("Payments that appear multiple times will show up here automatically.")
                    )
                    .padding(.top, 40)
                } else {
                    LazyVStack(spacing: 0) {
                        ForEach(recurringGroups) { group in
                            RecurringRowView(group: group)
                            Divider().padding(.leading, 56)
                        }
                    }
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
    }

    private func estimatedFrequency(_ dates: [Date]) -> PaymentFrequency {
        guard dates.count >= 2 else { return .monthly }
        let sorted = dates.sorted()
        let gaps = zip(sorted, sorted.dropFirst()).map {
            Calendar.current.dateComponents([.day], from: $0, to: $1).day ?? 30
        }
        let avgGap = gaps.reduce(0, +) / gaps.count
        switch avgGap {
        case ..<10:  return .weekly
        case 10..<20: return .biweekly
        case 20..<45: return .monthly
        default:     return .yearly
        }
    }
}

// MARK: - Models

struct RecurringGroup: Identifiable {
    let id = UUID()
    let name: String
    let category: String
    let occurrences: Int
    let averageAmount: Double
    let lastDate: Date
    let frequency: PaymentFrequency

    var monthlyEstimate: Double {
        switch frequency {
        case .weekly:    return averageAmount * 4.33
        case .biweekly:  return averageAmount * 2.17
        case .monthly:   return averageAmount
        case .yearly:    return averageAmount / 12
        }
    }
}

enum PaymentFrequency: String {
    case weekly    = "Weekly"
    case biweekly  = "Bi-weekly"
    case monthly   = "Monthly"
    case yearly    = "Yearly"
}

// MARK: - Row

private struct RecurringRowView: View {
    let group: RecurringGroup

    private var categoryIcon: String {
        switch group.category.lowercased() {
        case "food", "groceries": return "🛒"
        case "transport", "transportation": return "🚗"
        case "shopping": return "🛍️"
        case "entertainment": return "🎬"
        case "bills", "utilities": return "💡"
        case "health", "healthcare": return "💊"
        case "travel": return "✈️"
        case "education": return "📚"
        case "savings": return "💰"
        default: return "🔄"
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Text(categoryIcon)
                .font(.title2)
                .frame(width: 44, height: 44)
                .background(Color(.tertiarySystemGroupedBackground))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(group.name)
                    .font(.subheadline.bold())
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text(group.frequency.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.12))
                        .foregroundStyle(.blue)
                        .clipShape(Capsule())
                    Text("\(group.occurrences)× detected")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text(group.averageAmount, format: .currency(code: "USD"))
                    .font(.subheadline.bold())
                    .foregroundStyle(.red)
                Text("Last: \(group.lastDate.formatted(.dateTime.month(.abbreviated).day()))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }
}

#Preview {
    RecurringPaymentsView()
        .modelContainer(for: TransactionModel.self, inMemory: true)
}
