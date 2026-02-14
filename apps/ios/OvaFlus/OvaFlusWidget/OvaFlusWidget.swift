import WidgetKit
import SwiftUI

struct BudgetWidgetEntry: TimelineEntry {
    let date: Date
    let totalBudget: Double
    let totalSpent: Double
    let portfolioValue: Double
    let portfolioDayChange: Double
}

struct OvaFlusWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> BudgetWidgetEntry {
        BudgetWidgetEntry(
            date: Date(),
            totalBudget: 3000,
            totalSpent: 1850,
            portfolioValue: 25430.50,
            portfolioDayChange: 342.18
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (BudgetWidgetEntry) -> Void) {
        let entry = BudgetWidgetEntry(
            date: Date(),
            totalBudget: 3000,
            totalSpent: 1850,
            portfolioValue: 25430.50,
            portfolioDayChange: 342.18
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<BudgetWidgetEntry>) -> Void) {
        // Load cached data for widget
        let totalBudget: Double = LocalDataManager.shared.load(forKey: "widget_total_budget") ?? 3000
        let totalSpent: Double = LocalDataManager.shared.load(forKey: "widget_total_spent") ?? 0
        let portfolioValue: Double = LocalDataManager.shared.load(forKey: "widget_portfolio_value") ?? 0
        let portfolioDayChange: Double = LocalDataManager.shared.load(forKey: "widget_portfolio_day_change") ?? 0

        let entry = BudgetWidgetEntry(
            date: Date(),
            totalBudget: totalBudget,
            totalSpent: totalSpent,
            portfolioValue: portfolioValue,
            portfolioDayChange: portfolioDayChange
        )

        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

struct BudgetWidgetView: View {
    let entry: BudgetWidgetEntry

    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            smallWidget
        case .systemMedium:
            mediumWidget
        default:
            smallWidget
        }
    }

    var smallWidget: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Budget")
                .font(.caption.bold())
                .foregroundStyle(.secondary)

            Text(entry.totalSpent, format: .currency(code: "USD"))
                .font(.title2.bold())

            ProgressView(value: entry.totalBudget > 0 ? entry.totalSpent / entry.totalBudget : 0)
                .tint(entry.totalSpent > entry.totalBudget * 0.9 ? .red : .blue)

            Text("\(entry.totalBudget - entry.totalSpent, format: .currency(code: "USD")) left")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
    }

    var mediumWidget: some View {
        HStack(spacing: 16) {
            // Budget section
            VStack(alignment: .leading, spacing: 8) {
                Text("Budget")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                Text(entry.totalSpent, format: .currency(code: "USD"))
                    .font(.title3.bold())
                ProgressView(value: entry.totalBudget > 0 ? entry.totalSpent / entry.totalBudget : 0)
                    .tint(entry.totalSpent > entry.totalBudget * 0.9 ? .red : .blue)
                Text("\(entry.totalBudget - entry.totalSpent, format: .currency(code: "USD")) left")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()

            // Portfolio section
            VStack(alignment: .leading, spacing: 8) {
                Text("Portfolio")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                Text(entry.portfolioValue, format: .currency(code: "USD"))
                    .font(.title3.bold())
                HStack(spacing: 2) {
                    Image(systemName: entry.portfolioDayChange >= 0 ? "arrow.up.right" : "arrow.down.right")
                        .font(.caption2)
                    Text(entry.portfolioDayChange, format: .currency(code: "USD"))
                        .font(.caption)
                }
                .foregroundStyle(entry.portfolioDayChange >= 0 ? .green : .red)
                Text("today")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
    }
}

struct OvaFlusWidget: Widget {
    let kind: String = "OvaFlusWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: OvaFlusWidgetProvider()) { entry in
            BudgetWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("OvaFlus Finance")
        .description("View your budget and portfolio at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemMedium) {
    OvaFlusWidget()
} timeline: {
    BudgetWidgetEntry(date: Date(), totalBudget: 3000, totalSpent: 1850, portfolioValue: 25430.50, portfolioDayChange: 342.18)
}
