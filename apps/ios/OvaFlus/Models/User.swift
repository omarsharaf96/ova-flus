import Foundation

struct User: Codable, Identifiable {
    let id: String
    var name: String
    var email: String
    var avatarURL: String?
    var subscriptionTier: SubscriptionTier
    var settings: UserSettings
    var createdAt: Date
    var updatedAt: Date

    enum SubscriptionTier: String, Codable {
        case free
        case premium
        case pro
    }
}

struct UserSettings: Codable {
    var currency: String
    var theme: AppTheme
    var notificationsEnabled: Bool
    var biometricEnabled: Bool
    var budgetAlertThreshold: Double

    enum AppTheme: String, Codable {
        case system
        case light
        case dark
    }
}
