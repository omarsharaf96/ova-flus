import SwiftUI
import Charts

struct PortfolioView: View {
    @EnvironmentObject var appState: AppState
    @State private var holdings: [Holding] = []
    @State private var selectedHolding: Holding?
    @State private var performanceData: [PerformancePoint] = []

    var totalValue: Double {
        holdings.reduce(0) { $0 + $1.currentValue }
    }

    var totalGain: Double {
        holdings.reduce(0) { $0 + $1.gain }
    }

    var body: some View {
        HSplitView {
            // Left: Holdings table + performance chart
            VStack(spacing: 0) {
                // Performance chart
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Portfolio Value")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text("$\(totalValue, specifier: "%.2f")")
                                .font(.title.weight(.bold))
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("Total Gain/Loss")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text("$\(totalGain, specifier: "%.2f")")
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(totalGain >= 0 ? .green : .red)
                        }
                    }

                    Chart(performanceData) { point in
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("Value", point.value)
                        )
                        .foregroundStyle(.blue)
                        AreaMark(
                            x: .value("Date", point.date),
                            y: .value("Value", point.value)
                        )
                        .foregroundStyle(.blue.opacity(0.1))
                    }
                    .frame(height: 180)
                }
                .padding()

                Divider()

                // Holdings table
                Table(holdings, selection: $selectedHolding) {
                    TableColumn("Symbol") { h in
                        Text(h.symbol)
                            .fontWeight(.semibold)
                            .font(.system(.body, design: .monospaced))
                    }
                    .width(min: 60, ideal: 70)

                    TableColumn("Name") { h in
                        Text(h.name)
                    }
                    .width(min: 100, ideal: 140)

                    TableColumn("Qty") { h in
                        Text("\(h.quantity, specifier: "%.2f")")
                            .monospacedDigit()
                    }
                    .width(min: 50, ideal: 60)

                    TableColumn("Avg Cost") { h in
                        Text("$\(h.avgCost, specifier: "%.2f")")
                            .monospacedDigit()
                    }
                    .width(min: 70, ideal: 80)

                    TableColumn("Price") { h in
                        Text("$\(h.currentPrice, specifier: "%.2f")")
                            .monospacedDigit()
                    }
                    .width(min: 70, ideal: 80)

                    TableColumn("Value") { h in
                        Text("$\(h.currentValue, specifier: "%.2f")")
                            .monospacedDigit()
                    }
                    .width(min: 80, ideal: 90)

                    TableColumn("Gain") { h in
                        Text("$\(h.gain, specifier: "%.2f")")
                            .monospacedDigit()
                            .foregroundStyle(h.gain >= 0 ? .green : .red)
                    }
                    .width(min: 70, ideal: 80)

                    TableColumn("Gain %") { h in
                        Text("\(h.gainPercent, specifier: "%.2f")%")
                            .monospacedDigit()
                            .foregroundStyle(h.gainPercent >= 0 ? .green : .red)
                    }
                    .width(min: 60, ideal: 70)
                }
            }

            // Right: Allocation pie chart
            VStack(alignment: .leading, spacing: 12) {
                Text("Allocation")
                    .font(.headline)

                Chart(holdings) { h in
                    SectorMark(
                        angle: .value("Value", h.currentValue),
                        innerRadius: .ratio(0.5)
                    )
                    .foregroundStyle(by: .value("Symbol", h.symbol))
                }
                .frame(height: 250)

                // Legend
                ForEach(holdings) { h in
                    HStack {
                        Text(h.symbol)
                            .fontWeight(.medium)
                        Spacer()
                        let pct = totalValue > 0 ? (h.currentValue / totalValue * 100) : 0
                        Text("\(pct, specifier: "%.1f")%")
                            .foregroundStyle(.secondary)
                    }
                    .font(.caption)
                }
            }
            .padding()
            .frame(width: 240)
        }
        .sheet(item: $selectedHolding) { holding in
            StockDetailView(holding: holding)
                .frame(minWidth: 600, minHeight: 500)
        }
        .navigationTitle("Portfolio")
    }
}

struct PerformancePoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}
