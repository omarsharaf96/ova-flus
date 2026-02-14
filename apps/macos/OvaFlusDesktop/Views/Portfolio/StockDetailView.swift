import SwiftUI
import Charts

struct StockDetailView: View {
    let holding: Holding
    @State private var historicalData: [PricePoint] = []
    @State private var newsItems: [NewsItem] = []
    @State private var selectedTimeRange: TimeRange = .oneMonth
    @Environment(\.dismiss) private var dismiss

    enum TimeRange: String, CaseIterable {
        case oneDay = "1D"
        case oneWeek = "1W"
        case oneMonth = "1M"
        case threeMonths = "3M"
        case oneYear = "1Y"
        case all = "ALL"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text(holding.symbol)
                        .font(.title.weight(.bold))
                    Text(holding.name)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("$\(holding.currentPrice, specifier: "%.2f")")
                        .font(.title2.weight(.semibold))
                    Text("\(holding.gain >= 0 ? "+" : "")\(holding.gainPercent, specifier: "%.2f")%")
                        .foregroundStyle(holding.gain >= 0 ? .green : .red)
                }
                Button("Done") { dismiss() }
                    .padding(.leading)
            }
            .padding()

            Divider()

            ScrollView {
                VStack(spacing: 20) {
                    // Historical chart
                    VStack(alignment: .leading, spacing: 8) {
                        Picker("Time Range", selection: $selectedTimeRange) {
                            ForEach(TimeRange.allCases, id: \.self) { range in
                                Text(range.rawValue).tag(range)
                            }
                        }
                        .pickerStyle(.segmented)

                        Chart(historicalData) { point in
                            LineMark(
                                x: .value("Date", point.date),
                                y: .value("Price", point.price)
                            )
                            .foregroundStyle(.blue)
                        }
                        .frame(height: 220)
                    }

                    Divider()

                    // Key metrics grid
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Key Metrics")
                            .font(.headline)

                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            MetricCell(title: "Shares", value: "\(holding.quantity, specifier: "%.2f")")
                            MetricCell(title: "Avg Cost", value: "$\(holding.avgCost, specifier: "%.2f")")
                            MetricCell(title: "Total Value", value: "$\(holding.currentValue, specifier: "%.2f")")
                            MetricCell(title: "Total Gain", value: "$\(holding.gain, specifier: "%.2f")")
                        }
                    }

                    Divider()

                    // News
                    VStack(alignment: .leading, spacing: 8) {
                        Text("News")
                            .font(.headline)

                        if newsItems.isEmpty {
                            Text("No recent news")
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding()
                        } else {
                            ForEach(newsItems) { item in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.title)
                                        .fontWeight(.medium)
                                    HStack {
                                        Text(item.source)
                                            .foregroundStyle(.secondary)
                                        Spacer()
                                        Text(item.date, style: .relative)
                                            .foregroundStyle(.secondary)
                                    }
                                    .font(.caption)
                                }
                                .padding(.vertical, 4)
                                Divider()
                            }
                        }
                    }
                }
                .padding()
            }
        }
    }
}

struct MetricCell: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.body.weight(.medium))
                .monospacedDigit()
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.secondary.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

struct PricePoint: Identifiable {
    let id = UUID()
    let date: Date
    let price: Double
}

struct NewsItem: Identifiable {
    let id = UUID()
    let title: String
    let source: String
    let date: Date
    let url: URL?
}
