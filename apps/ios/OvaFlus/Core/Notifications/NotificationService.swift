import Foundation
import UserNotifications
import SwiftUI

@MainActor
final class NotificationService: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationService()
    private let center = UNUserNotificationCenter.current()

    private override init() {
        super.init()
        center.delegate = self
    }

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            return granted
        } catch {
            return false
        }
    }

    func checkBudgetAlert(budget: BudgetModel, threshold: Double = 0.8) {
        guard UserDefaults.standard.bool(forKey: "notificationsEnabled") else { return }
        guard budget.progress >= threshold else { return }

        let content = UNMutableNotificationContent()
        content.title = "Budget Alert"
        content.body = "\(budget.name) is at \(Int(budget.progress * 100))% of budget"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let requestID = "budget-alert-\(budget.id)"
        let request = UNNotificationRequest(identifier: requestID, content: content, trigger: trigger)

        center.add(request) { _ in }
    }

    func scheduleWeeklySummary() {
        center.removePendingNotificationRequests(withIdentifiers: ["weekly-summary"])
        guard UserDefaults.standard.bool(forKey: "notificationsEnabled") else { return }

        let content = UNMutableNotificationContent()
        content.title = "Weekly Finance Summary"
        content.body = "Check your weekly spending and portfolio performance"
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.weekday = 1  // Sunday
        dateComponents.hour = 19
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "weekly-summary", content: content, trigger: trigger)

        center.add(request) { _ in }
    }

    func sendGoalCompletedNotification(goalName: String) {
        let content = UNMutableNotificationContent()
        content.title = "Goal Achieved! 🎉"
        content.body = "You've reached your \(goalName) goal!"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let requestID = "goal-completed-\(goalName.replacingOccurrences(of: " ", with: "-"))-\(Int(Date().timeIntervalSince1970))"
        let request = UNNotificationRequest(identifier: requestID, content: content, trigger: trigger)

        center.add(request) { _ in }
    }

    func cancelBudgetAlerts(for budgetId: String) {
        let id = "budget-alert-\(budgetId)"
        center.removePendingNotificationRequests(withIdentifiers: [id])
        center.removeDeliveredNotifications(withIdentifiers: [id])
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .badge, .sound])
    }
}
