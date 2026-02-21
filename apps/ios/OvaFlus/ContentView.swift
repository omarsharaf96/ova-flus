import SwiftUI
import SwiftData

struct ContentView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab: Tab = .dashboard
    @State private var showAddTransaction = false

    enum Tab { case dashboard, budget, analytics, stocks, profile }

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                DashboardView()
                    .tabItem { Label("Dashboard", systemImage: "chart.bar.fill") }
                    .tag(Tab.dashboard)
                BudgetListView()
                    .tabItem { Label("Budget", systemImage: "dollarsign.circle.fill") }
                    .tag(Tab.budget)
                AnalyticsView()
                    .tabItem { Label("Analytics", systemImage: "chart.xyaxis.line") }
                    .tag(Tab.analytics)
                PortfolioView()
                    .tabItem { Label("Stocks", systemImage: "chart.line.uptrend.xyaxis") }
                    .tag(Tab.stocks)
                ProfileView()
                    .tabItem { Label("More", systemImage: "ellipsis.circle.fill") }
                    .tag(Tab.profile)
            }
            .tint(.blue)
        }
        .sheet(isPresented: $showAddTransaction) {
            AddTransactionView()
        }
        .onAppear {
            DataMigrationService.shared.migrateIfNeeded(modelContext: modelContext)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthManager())
}
