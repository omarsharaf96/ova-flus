import SwiftUI
import Charts

struct StockDetailView: View {
    let symbol: String
    @StateObject private var viewModel = StocksViewModel()
    @State private var selectedTimeRange: PortfolioView.TimeRange = .oneMonth

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Price header
                if let quote = viewModel.selectedQuote {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(quote.companyName)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(quote.price, format: .currency(code: "USD"))
                            .font(.system(size: 34, weight: .bold))
                        HStack(spacing: 4) {
                            Image(systemName: quote.change >= 0 ? "arrow.up.right" : "arrow.down.right")
                            Text(quote.change, format: .currency(code: "USD"))
                            Text("(\(String(format: "%.2f", quote.changePercent))%)")
                        }
                        .font(.subheadline)
                        .foregroundStyle(quote.change >= 0 ? .green : .red)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                }

                // Price chart
                Chart(viewModel.chartData, id: \.date) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Price", point.value)
                    )
                    .foregroundStyle(.blue)
                    .interpolationMethod(.catmullRom)
                }
                .frame(height: 250)
                .padding()

                Picker("Time Range", selection: $selectedTimeRange) {
                    ForEach(PortfolioView.TimeRange.allCases, id: \.self) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                // Key metrics
                if let quote = viewModel.selectedQuote {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Key Metrics")
                            .font(.headline)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            MetricRow(label: "Open", value: String(format: "%.2f", quote.open))
                            MetricRow(label: "High", value: String(format: "%.2f", quote.high))
                            MetricRow(label: "Low", value: String(format: "%.2f", quote.low))
                            MetricRow(label: "Volume", value: formatVolume(quote.volume))
                            MetricRow(label: "Market Cap", value: formatMarketCap(quote.marketCap))
                            MetricRow(label: "P/E Ratio", value: quote.peRatio.map { String(format: "%.2f", $0) } ?? "N/A")
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }

                // News
                VStack(alignment: .leading, spacing: 12) {
                    Text("News")
                        .font(.headline)

                    ForEach(viewModel.news, id: \.title) { article in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(article.title)
                                .font(.subheadline.bold())
                            Text(article.source)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(article.publishedAt, style: .relative)
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, 4)
                        Divider()
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding()
        }
        .navigationTitle(symbol)
        .task {
            await viewModel.fetchStockDetail(symbol: symbol)
        }
    }

    private func formatVolume(_ volume: Int) -> String {
        if volume >= 1_000_000 {
            return "\(String(format: "%.1f", Double(volume) / 1_000_000))M"
        } else if volume >= 1_000 {
            return "\(String(format: "%.1f", Double(volume) / 1_000))K"
        }
        return "\(volume)"
    }

    private func formatMarketCap(_ cap: Double) -> String {
        if cap >= 1_000_000_000_000 {
            return "$\(String(format: "%.2f", cap / 1_000_000_000_000))T"
        } else if cap >= 1_000_000_000 {
            return "$\(String(format: "%.2f", cap / 1_000_000_000))B"
        }
        return "$\(String(format: "%.2f", cap / 1_000_000))M"
    }
}

struct MetricRow: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.bold())
        }
    }
}
