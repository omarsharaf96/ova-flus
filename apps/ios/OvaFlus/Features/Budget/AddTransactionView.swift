import SwiftUI
import SwiftData

struct AddTransactionView: View {
    var budget: BudgetModel? = nil

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var amount: String = ""
    @State private var selectedCategory: String = "Food & Dining"
    @State private var transactionType: String = "expense"
    @State private var date = Date()
    @State private var merchantName: String = ""
    @State private var notes: String = ""
    @State private var showCamera = false
    @State private var isRecurring: Bool = false
    @State private var recurringFrequency: String = "Monthly"

    private let frequencies = ["Weekly", "Bi-weekly", "Monthly", "Yearly"]
    private let categories = [
        "Food & Dining", "Transportation", "Shopping", "Entertainment",
        "Bills & Utilities", "Health & Fitness", "Travel", "Education",
        "Personal Care", "Gifts & Donations", "Income", "Other"
    ]

    var body: some View {
        NavigationStack {
            Form {
                // Transaction type
                Section {
                    Picker("Type", selection: $transactionType) {
                        Text("Expense").tag("expense")
                        Text("Income").tag("income")
                    }
                    .pickerStyle(.segmented)
                }

                // Amount
                Section("Amount") {
                    HStack {
                        Text("$")
                            .font(.title2.bold())
                        TextField("0.00", text: $amount)
                            .keyboardType(.decimalPad)
                            .font(.title2.bold())
                    }
                }

                // Details
                Section("Details") {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(categories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }

                    DatePicker("Date", selection: $date, displayedComponents: .date)

                    TextField("Merchant Name", text: $merchantName)

                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)

                    Toggle("Recurring", isOn: $isRecurring)

                    if isRecurring {
                        Picker("Frequency", selection: $recurringFrequency) {
                            ForEach(frequencies, id: \.self) { freq in
                                Text(freq).tag(freq)
                            }
                        }
                    }
                }

                // Receipt
                Section("Receipt") {
                    Button {
                        showCamera = true
                        #if canImport(UIKit)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        #endif
                    } label: {
                        Label("Scan Receipt", systemImage: "camera.fill")
                    }
                }
            }
            .navigationTitle("Add Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveTransaction()
                    }
                    .disabled(amount.isEmpty)
                }
            }
            .sheet(isPresented: $showCamera) {
                Text("Camera View Placeholder")
            }
        }
    }

    private func saveTransaction() {
        guard let amountValue = Double(amount), amountValue > 0 else { return }

        let transaction = TransactionModel(
            amount: amountValue,
            type: transactionType,
            category: selectedCategory,
            merchantName: merchantName.isEmpty ? nil : merchantName,
            notes: notes.isEmpty ? nil : notes,
            date: date,
            budgetId: budget?.id,
            budget: budget,
            isRecurring: isRecurring,
            recurringFrequency: isRecurring ? recurringFrequency : nil
        )
        modelContext.insert(transaction)

        if transactionType == "expense", let budget = budget {
            budget.spent += amountValue
            budget.updatedAt = Date()

            let threshold = UserDefaults.standard.double(forKey: "budgetAlertThreshold") > 0
                ? UserDefaults.standard.double(forKey: "budgetAlertThreshold")
                : 0.8
            NotificationService.shared.checkBudgetAlert(budget: budget, threshold: threshold)
        }

        #if canImport(UIKit)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif
        dismiss()
    }
}

#Preview {
    AddTransactionView()
        .modelContainer(for: TransactionModel.self, inMemory: true)
}
