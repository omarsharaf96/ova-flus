import SwiftUI
import SwiftData

struct GoalsView: View {
    @Query(filter: #Predicate<GoalModel> { !$0.isCompleted }, sort: \GoalModel.createdAt) var activeGoals: [GoalModel]
    @Query(filter: #Predicate<GoalModel> { $0.isCompleted }, sort: \GoalModel.createdAt) var completedGoals: [GoalModel]
    @Environment(\.modelContext) private var modelContext
    @State private var showAddGoal = false

    var body: some View {
        NavigationStack {
            List {
                if !activeGoals.isEmpty {
                    Section("Active Goals") {
                        ForEach(activeGoals) { goal in
                            NavigationLink(destination: GoalDetailView(goal: goal)) {
                                GoalRowView(goal: goal)
                            }
                        }
                        .onDelete { indexSet in
                            indexSet.forEach { modelContext.delete(activeGoals[$0]) }
                        }
                    }
                }
                if !completedGoals.isEmpty {
                    Section("Completed Goals") {
                        ForEach(completedGoals) { goal in
                            NavigationLink(destination: GoalDetailView(goal: goal)) {
                                GoalRowView(goal: goal)
                            }
                        }
                        .onDelete { indexSet in
                            indexSet.forEach { modelContext.delete(completedGoals[$0]) }
                        }
                    }
                }
                if activeGoals.isEmpty && completedGoals.isEmpty {
                    ContentUnavailableView("No Goals Yet", systemImage: "target", description: Text("Tap + to add your first financial goal"))
                }
            }
            .navigationTitle("Financial Goals")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showAddGoal = true } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showAddGoal) { AddGoalView() }
        }
    }
}

struct GoalRowView: View {
    let goal: GoalModel

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(hex: goal.colorHex))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: goal.iconName)
                        .foregroundColor(.white)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(goal.name).font(.headline)
                ProgressView(value: min(goal.progress, 1.0))
                    .tint(Color(hex: goal.colorHex))
                HStack {
                    Text(String(format: "$%.0f / $%.0f", goal.currentAmount, goal.targetAmount))
                        .font(.caption).foregroundColor(.secondary)
                    Spacer()
                    if goal.isCompleted {
                        Text("Completed").font(.caption).foregroundColor(.green)
                    } else if let days = goal.daysRemaining {
                        Text("\(days)d left").font(.caption).foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}
