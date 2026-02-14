import Foundation

struct User: Identifiable, Codable {
    let id: String
    let email: String
    let name: String
    let avatarURL: String?
    let subscriptionTier: SubscriptionTier
    let createdAt: Date

    enum SubscriptionTier: String, Codable {
        case free
        case premium
    }
}
