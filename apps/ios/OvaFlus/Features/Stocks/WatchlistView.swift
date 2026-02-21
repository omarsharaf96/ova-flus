import SwiftUI
import SwiftData

struct WatchlistView: View {
    @StateObject private var viewModel = StocksViewModel()
    @Query(sort: \WatchlistItemModel.addedAt, order: .reverse) var watchlistItems: [WatchlistItemModel]
    @Environment(\.modelContext) private var modelContext
    @State private var searchText = ""
    @State private var showSearch = false

    var body: some View {
        List {
            ForEach(viewModel.watchlist) { quote in
                NavigationLink {
                    StockDetailView(symbol: quote.symbol)
                } label: {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(quote.symbol)
                                .font(.subheadline.bold())
                            Text(quote.companyName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text(quote.price, format: .currency(code: "USD"))
                                .font(.subheadline.bold())
                            HStack(spacing: 2) {
                                Image(systemName: quote.change >= 0 ? "arrow.up.right" : "arrow.down.right")
                                    .font(.caption2)
                                Text("\(quote.changePercent, specifier: "%+.2f")%")
                                    .font(.caption)
                            }
                            .foregroundStyle(quote.change >= 0 ? .green : .red)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
            .onDelete { indexSet in
                Task {
                    for index in indexSet {
                        await viewModel.removeFromWatchlist(viewModel.watchlist[index].symbol)
                    }
                }
            }
        }
        .navigationTitle("Watchlist")
        .searchable(text: $searchText, prompt: "Search stocks")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showSearch = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showSearch) {
            StockSearchView { quote in
                let item = WatchlistItemModel(symbol: quote.symbol)
                modelContext.insert(item)
                Task {
                    await viewModel.addToWatchlist(symbol: quote.symbol)
                }
            }
        }
        .refreshable {
            await viewModel.fetchWatchlist()
        }
        .task {
            await viewModel.fetchWatchlist()
        }
    }
}

#Preview {
    NavigationStack {
        WatchlistView()
    }
}
