import SwiftUI
import SwiftData

struct AddBudgetView: View {
    var existingBudget: BudgetModel? = nil

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State var name: String = ""
    @State var category: String = "Food"
    @State var amount: String = ""
    @State var period: String = "monthly"
    @State var startDate: Date = Date()

    private let categories = [
        "Food", "Transport", "Shopping", "Entertainment", "Health",
        "Housing", "Education", "Travel", "Dining", "Other"
    ]

    private let periods = ["weekly", "biweekly", "monthly", "yearly"]

    private var endDate: Date {
        let calendar = Calendar.current
        switch period {
        case "weekly":
            return calendar.date(byAdding: .day, value: 7, to: startDate) ?? startDate
        case "biweekly":
            return calendar.date(byAdding: .day, value: 14, to: startDate) ?? startDate
        case "monthly":
            return calendar.date(byAdding: .month, value: 1, to: startDate) ?? startDate
        case "yearly":
            return calendar.date(byAdding: .year, value: 1, to: startDate) ?? startDate
        default:
            return calendar.date(byAdding: .month, value: 1, to: startDate) ?? startDate
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Budget Name") {
                    TextField("e.g. Groceries", text: $name)
                }

                Section("Category") {
                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) { cat in
                            Text(cat).tag(cat)
                        }
                    }
                }

                Section("Amount") {
                    HStack {
                        Text("$")
                            .font(.title2.bold())
                        TextField("0.00", text: $amount)
                            .keyboardType(.decimalPad)
                            .font(.title2.bold())
                    }
                }

                Section("Period") {
                    Picker("Period", selection: $period) {
                        ForEach(periods, id: \.self) { p in
                            Text(p.capitalized).tag(p)
                        }
                    }
                }

                Section("Start Date") {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                }
            }
            .navigationTitle(existingBudget != nil ? "Edit Budget" : "Add Budget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveBudget()
                    }
                    .disabled(amount.isEmpty || (Double(amount) ?? 0) <= 0)
                }
            }
            .onAppear {
                if let budget = existingBudget {
                    name = budget.name
                    category = budget.category
                    amount = String(budget.amount)
                    period = budget.period
                    startDate = budget.startDate
                }
            }
        }
    }

    private func saveBudget() {
        guard let amountValue = Double(amount), amountValue > 0 else { return }

        if let budget = existingBudget {
            budget.name = name
            budget.category = category
            budget.amount = amountValue
            budget.period = period
            budget.startDate = startDate
            budget.endDate = endDate
            budget.updatedAt = Date()
        } else {
            let budget = BudgetModel(
                name: name,
                category: category,
                amount: amountValue,
                period: period,
                startDate: startDate,
                endDate: endDate
            )
            modelContext.insert(budget)
        }

        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        #endif
        dismiss()
    }
}

#Preview {
    AddBudgetView()
        .modelContainer(for: BudgetModel.self, inMemory: true)
}
