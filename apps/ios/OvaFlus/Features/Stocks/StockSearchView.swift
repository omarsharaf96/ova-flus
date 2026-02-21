import SwiftUI

struct StockSearchView: View {
    let onSelect: (StockQuote) -> Void
    @StateObject private var viewModel = StocksViewModel()
    @State private var searchText: String = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isSearching {
                    ProgressView("Searching...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if searchText.count >= 2 && viewModel.searchResults.isEmpty {
                    ContentUnavailableView("No Results", systemImage: "magnifyingglass", description: Text("Try searching for a stock symbol or company name"))
                } else {
                    List(viewModel.searchResults) { quote in
                        Button {
                            onSelect(quote)
                            dismiss()
                        } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(quote.symbol).font(.headline)
                                    Text(quote.companyName).font(.caption).foregroundColor(.secondary)
                                }
                                Spacer()
                                Text("$\(quote.price, specifier: "%.2f")").font(.subheadline)
                            }
                        }
                        .foregroundColor(.primary)
                    }
                }
            }
            .navigationTitle("Search Stocks")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
            .onChange(of: searchText) { _, newValue in
                Task {
                    try? await Task.sleep(nanoseconds: 300_000_000)
                    await viewModel.searchStocks(query: newValue)
                }
            }
        }
    }
}
