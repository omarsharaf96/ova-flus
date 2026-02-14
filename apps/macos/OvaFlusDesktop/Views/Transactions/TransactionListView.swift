import SwiftUI

struct TransactionListView: View {
    @State private var transactions: [Transaction] = []
    @State private var selectedTransactions = Set<Transaction.ID>()
    @State private var searchText = ""
    @State private var sortOrder = [KeyPathComparator(\Transaction.date, order: .reverse)]
    @State private var filterCategory: String? = nil
    @State private var filterDateFrom: Date? = nil
    @State private var filterDateTo: Date? = nil
    @State private var showingAddSheet = false
    @State private var showingImportSheet = false

    let categories = [
        "All", "Food & Dining", "Shopping", "Transportation",
        "Bills & Utilities", "Entertainment", "Health", "Travel", "Other"
    ]

    var filteredTransactions: [Transaction] {
        transactions.filter { tx in
            let matchesSearch = searchText.isEmpty ||
                tx.merchant.localizedCaseInsensitiveContains(searchText) ||
                tx.category.localizedCaseInsensitiveContains(searchText)
            let matchesCategory = filterCategory == nil || filterCategory == "All" ||
                tx.category == filterCategory
            let matchesDateFrom = filterDateFrom == nil || tx.date >= filterDateFrom!
            let matchesDateTo = filterDateTo == nil || tx.date <= filterDateTo!
            return matchesSearch && matchesCategory && matchesDateFrom && matchesDateTo
        }
        .sorted(using: sortOrder)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Filter toolbar
            HStack {
                Picker("Category", selection: $filterCategory) {
                    Text("All Categories").tag(String?.none)
                    ForEach(categories, id: \.self) { cat in
                        Text(cat).tag(Optional(cat))
                    }
                }
                .frame(width: 180)

                DatePicker("From", selection: Binding(
                    get: { filterDateFrom ?? Calendar.current.date(byAdding: .month, value: -1, to: Date())! },
                    set: { filterDateFrom = $0 }
                ), displayedComponents: .date)
                .frame(width: 180)

                DatePicker("To", selection: Binding(
                    get: { filterDateTo ?? Date() },
                    set: { filterDateTo = $0 }
                ), displayedComponents: .date)
                .frame(width: 180)

                Spacer()

                Button {
                    showingImportSheet = true
                } label: {
                    Label("Import CSV", systemImage: "square.and.arrow.down")
                }

                Button {
                    showingAddSheet = true
                } label: {
                    Label("Add", systemImage: "plus")
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            Divider()

            // Transactions table
            Table(filteredTransactions, selection: $selectedTransactions, sortOrder: $sortOrder) {
                TableColumn("Date", sortUsing: KeyPathComparator(\Transaction.date)) { tx in
                    Text(tx.date, style: .date)
                }
                .width(min: 80, ideal: 110)

                TableColumn("Merchant", sortUsing: KeyPathComparator(\Transaction.merchant)) { tx in
                    Text(tx.merchant)
                }
                .width(min: 120, ideal: 180)

                TableColumn("Category", sortUsing: KeyPathComparator(\Transaction.category)) { tx in
                    Text(tx.category)
                }
                .width(min: 100, ideal: 130)

                TableColumn("Amount", sortUsing: KeyPathComparator(\Transaction.amount)) { tx in
                    Text("$\(tx.amount, specifier: "%.2f")")
                        .foregroundStyle(tx.amount < 0 ? .red : .green)
                        .monospacedDigit()
                }
                .width(min: 80, ideal: 100)
            }
            .contextMenu(forSelectionType: Transaction.ID.self) { ids in
                Button("Edit") {
                    // TODO: Open edit sheet
                }
                Button("Recategorize...") {
                    // TODO: Open recategorize sheet
                }
                Divider()
                Button("Delete", role: .destructive) {
                    // TODO: Delete selected transactions
                }
            } primaryAction: { ids in
                // Double-click to edit
            }
            .searchable(text: $searchText, prompt: "Search transactions...")
        }
        .sheet(isPresented: $showingAddSheet) {
            AddTransactionSheet()
        }
        .navigationTitle("Transactions")
    }
}
