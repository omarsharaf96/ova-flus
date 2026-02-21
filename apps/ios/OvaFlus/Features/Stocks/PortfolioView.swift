import SwiftUI
import Charts
import SwiftData

struct PortfolioView: View {
    @StateObject private var viewModel = StocksViewModel()
    @Query var holdings: [HoldingModel]
    @State private var selectedTimeRange: TimeRange = .oneMonth
    @State private var showAddHolding = false

    enum TimeRange: String, CaseIterable {
        case oneDay = "1D"
        case oneWeek = "1W"
        case oneMonth = "1M"
        case threeMonths = "3M"
        case oneYear = "1Y"
        case all = "ALL"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Portfolio value header
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Total Value")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(viewModel.portfolio?.totalValue ?? 0, format: .currency(code: "USD"))
                            .font(.system(size: 34, weight: .bold))
                        HStack(spacing: 4) {
                            Image(systemName: (viewModel.portfolio?.dayChange ?? 0) >= 0 ? "arrow.up.right" : "arrow.down.right")
                            Text(viewModel.portfolio?.dayChange ?? 0, format: .currency(code: "USD"))
                            Text("(\(viewModel.portfolio?.dayChangePercent ?? 0, specifier: "%.2f")%)")
                        }
                        .font(.subheadline)
                        .foregroundStyle((viewModel.portfolio?.dayChange ?? 0) >= 0 ? .green : .red)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)

                    // Performance chart
                    VStack {
                        Chart(viewModel.chartData, id: \.date) { point in
                            LineMark(
                                x: .value("Date", point.date),
                                y: .value("Value", point.value)
                            )
                            .foregroundStyle((viewModel.portfolio?.dayChange ?? 0) >= 0 ? .green : .red)
                            .interpolationMethod(.catmullRom)

                            AreaMark(
                                x: .value("Date", point.date),
                                y: .value("Value", point.value)
                            )
                            .foregroundStyle(
                                .linearGradient(
                                    colors: [(viewModel.portfolio?.dayChange ?? 0) >= 0 ? .green.opacity(0.2) : .red.opacity(0.2), .clear],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        }
                        .frame(height: 200)
                        .chartXAxis(.hidden)

                        // Time range picker
                        Picker("Time Range", selection: $selectedTimeRange) {
                            ForEach(TimeRange.allCases, id: \.self) { range in
                                Text(range.rawValue).tag(range)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    // Allocation chart
                    if !holdings.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Allocation")
                                .font(.headline)

                            Chart(holdings, id: \.symbol) { holding in
                                SectorMark(
                                    angle: .value("Value", holding.shares * holding.averageCost),
                                    innerRadius: .ratio(0.5)
                                )
                                .foregroundStyle(by: .value("Symbol", holding.symbol))
                            }
                            .frame(height: 200)
                            .chartLegend(position: .trailing)
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }

                    // Holdings list
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Holdings")
                                .font(.headline)
                            Spacer()
                            NavigationLink("Watchlist") {
                                WatchlistView()
                            }
                            .font(.subheadline)
                        }

                        ForEach(viewModel.portfolio?.holdings ?? []) { holding in
                            NavigationLink {
                                StockDetailView(symbol: holding.symbol)
                            } label: {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(holding.symbol)
                                            .font(.subheadline.bold())
                                        Text("\(holding.shares, specifier: "%.2f") shares")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    VStack(alignment: .trailing) {
                                        Text(holding.currentValue, format: .currency(code: "USD"))
                                            .font(.subheadline.bold())
                                        Text("\(holding.dayChangePercent, specifier: "%+.2f")%")
                                            .font(.caption)
                                            .foregroundStyle(holding.dayChangePercent >= 0 ? .green : .red)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                            .buttonStyle(.plain)
                            Divider()
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding()
            }
            .navigationTitle("Stocks")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAddHolding = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddHolding) {
                AddHoldingView()
            }
            .refreshable {
                await viewModel.fetchPortfolio()
            }
            .task {
                await viewModel.fetchPortfolio()
            }
        }
    }
}

#Preview {
    PortfolioView()
}
