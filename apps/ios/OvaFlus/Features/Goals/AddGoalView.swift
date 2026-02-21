import SwiftUI
import SwiftData

struct AddGoalView: View {
    var existingGoal: GoalModel? = nil
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var category: String = "savings"
    @State private var targetAmount: String = ""
    @State private var startingAmount: String = "0"
    @State private var hasDeadline: Bool = false
    @State private var deadline: Date = Date().addingTimeInterval(86400 * 30)
    @State private var iconName: String = "target"
    @State private var colorHex: String = "#007AFF"

    let categories = ["savings", "debt_payoff", "emergency_fund", "investment", "custom"]
    let categoryLabels = ["Savings", "Debt Payoff", "Emergency Fund", "Investment", "Custom"]
    let icons = ["target", "house.fill", "car.fill", "airplane", "cart.fill", "heart.fill", "star.fill", "dollarsign.circle.fill", "chart.bar.fill", "trophy.fill"]
    let colors = ["#007AFF", "#34C759", "#FF9500", "#FF3B30", "#AF52DE", "#5856D6", "#FF2D55", "#00C7BE"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Goal Details") {
                    TextField("Goal name", text: $name)
                    Picker("Category", selection: $category) {
                        ForEach(0..<categories.count, id: \.self) { i in
                            Text(categoryLabels[i]).tag(categories[i])
                        }
                    }
                }
                Section("Amounts") {
                    HStack {
                        Text("$")
                        TextField("Target amount", text: $targetAmount)
                            .keyboardType(.decimalPad)
                    }
                    HStack {
                        Text("$")
                        TextField("Starting amount (optional)", text: $startingAmount)
                            .keyboardType(.decimalPad)
                    }
                }
                Section("Deadline") {
                    Toggle("Has Deadline", isOn: $hasDeadline)
                    if hasDeadline {
                        DatePicker("Deadline", selection: $deadline, in: Date()..., displayedComponents: .date)
                    }
                }
                Section("Icon") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(icons, id: \.self) { icon in
                                Image(systemName: icon)
                                    .font(.title2)
                                    .padding(10)
                                    .background(iconName == icon ? Color.accentColor.opacity(0.2) : Color(.systemGray6))
                                    .cornerRadius(8)
                                    .onTapGesture { iconName = icon }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                Section("Color") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(colors, id: \.self) { hex in
                                Circle()
                                    .fill(Color(hex: hex))
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Circle().stroke(Color.primary, lineWidth: colorHex == hex ? 2 : 0)
                                    )
                                    .onTapGesture { colorHex = hex }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle(existingGoal == nil ? "New Goal" : "Edit Goal")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard !name.isEmpty, let target = Double(targetAmount), target > 0 else { return }
                        let current = Double(startingAmount) ?? 0
                        if let existing = existingGoal {
                            existing.name = name
                            existing.category = category
                            existing.targetAmount = target
                            existing.iconName = iconName
                            existing.colorHex = colorHex
                            existing.deadline = hasDeadline ? deadline : nil
                        } else {
                            let goal = GoalModel(name: name, targetAmount: target, currentAmount: current, deadline: hasDeadline ? deadline : nil, category: category, iconName: iconName, colorHex: colorHex)
                            modelContext.insert(goal)
                        }
                        dismiss()
                    }
                }
            }
            .onAppear {
                if let goal = existingGoal {
                    name = goal.name
                    category = goal.category
                    targetAmount = String(goal.targetAmount)
                    startingAmount = String(goal.currentAmount)
                    iconName = goal.iconName
                    colorHex = goal.colorHex
                    if let d = goal.deadline { hasDeadline = true; deadline = d }
                }
            }
        }
    }
}
