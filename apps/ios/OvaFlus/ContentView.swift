import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var selectedTab: Tab = .dashboard
    @State private var showAddTransaction = false

    enum Tab { case dashboard, budget, stocks, profile }

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                DashboardView()
                    .tabItem { Label("Dashboard", systemImage: "chart.bar.fill") }
                    .tag(Tab.dashboard)
                BudgetListView()
                    .tabItem { Label("Budget", systemImage: "dollarsign.circle.fill") }
                    .tag(Tab.budget)
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
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthManager())
}
