import SwiftUI

struct MainWindowView: View {
    @State private var selectedSection: AppSection? = .dashboard

    enum AppSection: String, CaseIterable, Identifiable {
        case dashboard = "Dashboard"
        case budgets = "Budgets"
        case transactions = "Transactions"
        case portfolio = "Portfolio"
        case watchlist = "Watchlist"
        case settings = "Settings"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .dashboard: return "chart.bar.fill"
            case .budgets: return "dollarsign.circle.fill"
            case .transactions: return "list.bullet.rectangle.fill"
            case .portfolio: return "chart.line.uptrend.xyaxis"
            case .watchlist: return "eye.fill"
            case .settings: return "gearshape.fill"
            }
        }
    }

    var body: some View {
        NavigationSplitView {
            List(AppSection.allCases, selection: $selectedSection) { section in
                Label(section.rawValue, systemImage: section.icon)
                    .tag(section)
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
        } detail: {
            switch selectedSection {
            case .dashboard: DashboardView()
            case .budgets: BudgetListView()
            case .transactions: TransactionListView()
            case .portfolio: PortfolioView()
            case .watchlist: WatchlistView()
            case .settings: SettingsView()
            case nil: DashboardView()
            }
        }
        .navigationTitle(selectedSection?.rawValue ?? "OvaFlus")
    }
}
