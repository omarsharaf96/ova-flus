import SwiftUI
import SwiftData

@main
struct OvaFlusApp: App {
    @StateObject private var authManager = AuthManager()

    let modelContainer: ModelContainer = {
        let schema = Schema([
            BudgetModel.self,
            TransactionModel.self,
            HoldingModel.self,
            GoalModel.self,
            WatchlistItemModel.self,
            LinkedBankAccountModel.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            if authManager.isAuthenticated {
                ContentView()
                    .environmentObject(authManager)
                    .modelContainer(modelContainer)
                    .task {
                        _ = await NotificationService.shared.requestAuthorization()
                        NotificationService.shared.scheduleWeeklySummary()
                    }
            } else {
                LoginView()
                    .environmentObject(authManager)
            }
        }
    }
}
