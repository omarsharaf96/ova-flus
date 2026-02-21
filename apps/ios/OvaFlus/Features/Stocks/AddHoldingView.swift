import SwiftUI
import SwiftData

struct AddHoldingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var selectedQuote: StockQuote? = nil
    @State private var shares: String = ""
    @State private var averageCost: String = ""
    @State private var purchaseDate: Date = Date()
    @State private var showSearch = false

    private var totalCost: Double {
        (Double(shares) ?? 0) * (Double(averageCost) ?? 0)
    }

    private var currentValue: Double {
        (Double(shares) ?? 0) * (selectedQuote?.price ?? 0)
    }

    private var canSave: Bool {
        selectedQuote != nil && (Double(shares) ?? 0) > 0 && (Double(averageCost) ?? 0) > 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Stock") {
                    Button {
                        showSearch = true
                    } label: {
                        HStack {
                            if let quote = selectedQuote {
                                VStack(alignment: .leading) {
                                    Text(quote.symbol).font(.headline).foregroundColor(.primary)
                                    Text(quote.companyName).font(.caption).foregroundColor(.secondary)
                                }
                            } else {
                                Text("Select Stock").foregroundColor(.accentColor)
                            }
                            Spacer()
                            Image(systemName: "chevron.right").foregroundColor(.secondary)
                        }
                    }
                }

                Section("Purchase Details") {
                    HStack {
                        Text("Shares")
                        Spacer()
                        TextField("0", text: $shares)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Avg Cost/Share")
                        Spacer()
                        Text("$")
                        TextField("0.00", text: $averageCost)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    DatePicker("Purchase Date", selection: $purchaseDate, displayedComponents: .date)
                }

                if selectedQuote != nil, (Double(shares) ?? 0) > 0 {
                    Section("Summary") {
                        HStack {
                            Text("Total Cost")
                            Spacer()
                            Text("$\(totalCost, specifier: "%.2f")")
                        }
                        HStack {
                            Text("Current Value")
                            Spacer()
                            Text("$\(currentValue, specifier: "%.2f")")
                        }
                        HStack {
                            Text("Return")
                            Spacer()
                            let returnAmt = currentValue - totalCost
                            Text("\(returnAmt >= 0 ? "+" : "")$\(returnAmt, specifier: "%.2f")")
                                .foregroundColor(returnAmt >= 0 ? .green : .red)
                        }
                    }
                }
            }
            .navigationTitle("Add Holding")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard canSave, let quote = selectedQuote else { return }
                        let holding = HoldingModel(
                            symbol: quote.symbol,
                            companyName: quote.companyName,
                            shares: Double(shares)!,
                            averageCost: Double(averageCost)!,
                            purchaseDate: purchaseDate
                        )
                        modelContext.insert(holding)
                        dismiss()
                    }
                    .disabled(!canSave)
                }
            }
            .sheet(isPresented: $showSearch) {
                StockSearchView { quote in
                    selectedQuote = quote
                    averageCost = String(format: "%.2f", quote.price)
                }
            }
        }
    }
}
