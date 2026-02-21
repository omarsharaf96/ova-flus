import SwiftUI
import SwiftData
import UserNotifications

struct GoalDetailView: View {
    @Bindable var goal: GoalModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var showAddFunds = false
    @State private var showEdit = false
    @State private var fundsAmount: String = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Circular progress ring
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 16)
                    Circle()
                        .trim(from: 0, to: CGFloat(min(goal.progress, 1.0)))
                        .stroke(Color(hex: goal.colorHex), style: StrokeStyle(lineWidth: 16, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    VStack {
                        Text("\(Int(goal.progress * 100))%")
                            .font(.largeTitle.bold())
                        Text("of goal")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(width: 180, height: 180)
                .padding()

                // Stats grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    StatCard(title: "Target", value: String(format: "$%.2f", goal.targetAmount))
                    StatCard(title: "Saved", value: String(format: "$%.2f", goal.currentAmount))
                    StatCard(title: "Remaining", value: String(format: "$%.2f", goal.remaining))
                    if let days = goal.daysRemaining {
                        StatCard(title: "Days Left", value: "\(days)")
                    } else {
                        StatCard(title: "Deadline", value: "None")
                    }
                }
                .padding(.horizontal)

                // Add Funds button
                if !goal.isCompleted {
                    Button {
                        showAddFunds = true
                    } label: {
                        Label("Add Funds", systemImage: "plus.circle.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(hex: goal.colorHex))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                } else {
                    Text("Goal Completed!")
                        .font(.headline)
                        .foregroundColor(.green)
                }
            }
            .padding()
        }
        .navigationTitle(goal.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button("Edit") { showEdit = true }
                    Button("Delete", role: .destructive) {
                        modelContext.delete(goal)
                        dismiss()
                    }
                } label: { Image(systemName: "ellipsis.circle") }
            }
        }
        .sheet(isPresented: $showEdit) { AddGoalView(existingGoal: goal) }
        .sheet(isPresented: $showAddFunds) {
            AddFundsView(goal: goal)
        }
    }
}

struct AddFundsView: View {
    @Bindable var goal: GoalModel
    @Environment(\.dismiss) private var dismiss
    @State private var amount: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Amount to Add") {
                    TextField("0.00", text: $amount)
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle("Add Funds")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        if let value = Double(amount), value > 0 {
                            goal.currentAmount += value
                            if goal.currentAmount >= goal.targetAmount {
                                goal.isCompleted = true
                                let content = UNMutableNotificationContent()
                                content.title = "Goal Achieved!"
                                content.body = "You've reached your \(goal.name) goal!"
                                content.sound = .default
                                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
                                let request = UNNotificationRequest(identifier: "goal-\(goal.id)", content: content, trigger: trigger)
                                UNUserNotificationCenter.current().add(request) { _ in }
                            }
                            dismiss()
                        }
                    }
                    .disabled(Double(amount) == nil || (Double(amount) ?? 0) <= 0)
                }
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(title).font(.caption).foregroundColor(.secondary)
            Text(value).font(.headline)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }
}
