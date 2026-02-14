import SwiftUI

struct AddTransactionView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = BudgetViewModel()

    @State private var amount: String = ""
    @State private var selectedCategory: String = "Food & Dining"
    @State private var transactionType: TransactionType = .expense
    @State private var date = Date()
    @State private var merchantName: String = ""
    @State private var notes: String = ""
    @State private var showCamera = false

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
                        Text("Expense").tag(TransactionType.expense)
                        Text("Income").tag(TransactionType.income)
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
                }

                // Receipt
                Section("Receipt") {
                    Button {
                        showCamera = true
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
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
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                        Task {
                            await saveTransaction()
                        }
                    }
                    .disabled(amount.isEmpty)
                }
            }
            .sheet(isPresented: $showCamera) {
                Text("Camera View Placeholder")
            }
        }
    }

    private func saveTransaction() async {
        guard let amountValue = Double(amount) else { return }
        let transaction = Transaction(
            id: UUID().uuidString,
            amount: amountValue,
            type: transactionType,
            category: selectedCategory,
            date: date,
            merchantName: merchantName.isEmpty ? nil : merchantName,
            notes: notes.isEmpty ? nil : notes
        )
        await viewModel.addTransaction(transaction)
        dismiss()
    }
}

#Preview {
    AddTransactionView()
}
