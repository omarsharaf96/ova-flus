import SwiftUI

struct WatchlistView: View {
    @State private var watchlistItems: [WatchlistItem] = []
    @State private var selectedItem: WatchlistItem?
    @State private var showingAddSymbol = false
    @State private var newSymbol = ""

    private let refreshTimer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                Text("Watchlist")
                    .font(.title2.weight(.bold))
                Spacer()
                HStack {
                    if showingAddSymbol {
                        TextField("Symbol", text: $newSymbol)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 100)
                            .onSubmit { addSymbol() }
                        Button("Add") { addSymbol() }
                            .disabled(newSymbol.isEmpty)
                        Button("Cancel") {
                            showingAddSymbol = false
                            newSymbol = ""
                        }
                    } else {
                        Button {
                            showingAddSymbol = true
                        } label: {
                            Label("Add Symbol", systemImage: "plus")
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            Divider()

            // Watchlist table
            Table(watchlistItems, selection: $selectedItem) {
                TableColumn("Symbol") { item in
                    Text(item.symbol)
                        .fontWeight(.semibold)
                        .font(.system(.body, design: .monospaced))
                }
                .width(min: 60, ideal: 80)

                TableColumn("Name") { item in
                    Text(item.name)
                }
                .width(min: 120, ideal: 180)

                TableColumn("Price") { item in
                    Text("$\(item.price, specifier: "%.2f")")
                        .monospacedDigit()
                }
                .width(min: 70, ideal: 90)

                TableColumn("Change") { item in
                    Text("\(item.change >= 0 ? "+" : "")\(item.change, specifier: "%.2f")")
                        .monospacedDigit()
                        .foregroundStyle(item.change >= 0 ? .green : .red)
                }
                .width(min: 70, ideal: 80)

                TableColumn("Change %") { item in
                    Text("\(item.changePercent >= 0 ? "+" : "")\(item.changePercent, specifier: "%.2f")%")
                        .monospacedDigit()
                        .foregroundStyle(item.changePercent >= 0 ? .green : .red)
                }
                .width(min: 70, ideal: 80)

                TableColumn("Volume") { item in
                    Text(formatVolume(item.volume))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
                .width(min: 70, ideal: 90)
            }
            .contextMenu(forSelectionType: WatchlistItem.ID.self) { ids in
                Button("View Details") {
                    // TODO: Open stock detail
                }
                Divider()
                Button("Remove from Watchlist", role: .destructive) {
                    watchlistItems.removeAll { ids.contains($0.id) }
                }
            }
        }
        .onReceive(refreshTimer) { _ in
            refreshPrices()
        }
        .navigationTitle("Watchlist")
    }

    private func addSymbol() {
        guard !newSymbol.isEmpty else { return }
        // TODO: Fetch symbol data from API and add to watchlist
        newSymbol = ""
        showingAddSymbol = false
    }

    private func refreshPrices() {
        // TODO: Fetch latest prices from API
    }

    private func formatVolume(_ volume: Int) -> String {
        if volume >= 1_000_000 {
            return "\(String(format: "%.1f", Double(volume) / 1_000_000))M"
        } else if volume >= 1_000 {
            return "\(String(format: "%.1f", Double(volume) / 1_000))K"
        }
        return "\(volume)"
    }
}

struct WatchlistItem: Identifiable, Hashable {
    let id: String
    let symbol: String
    let name: String
    var price: Double
    var change: Double
    var changePercent: Double
    var volume: Int
}
