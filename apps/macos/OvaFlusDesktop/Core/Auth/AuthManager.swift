import Foundation
import Security

final class AuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?

    private static let serviceName = "com.ovaflus.desktop"
    private static let tokenKey = "auth_token"

    init() {
        if let token = Self.getToken(), !token.isEmpty {
            isAuthenticated = true
            Task { await loadCurrentUser() }
        }
    }

    // MARK: - Auth Actions

    func signIn(email: String, password: String) async throws {
        struct SignInRequest: Encodable {
            let email: String
            let password: String
        }
        struct SignInResponse: Decodable {
            let token: String
            let user: User
        }

        let response: SignInResponse = try await APIClient.shared.post(
            "/auth/login",
            body: SignInRequest(email: email, password: password)
        )

        Self.saveToken(response.token)

        await MainActor.run {
            self.currentUser = response.user
            self.isAuthenticated = true
        }
    }

    func signOut() {
        Self.deleteToken()
        currentUser = nil
        isAuthenticated = false
    }

    func loadCurrentUser() async {
        do {
            let user: User = try await APIClient.shared.get("/auth/me")
            await MainActor.run {
                self.currentUser = user
            }
        } catch {
            signOut()
        }
    }

    // MARK: - Keychain

    static func getToken() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: tokenKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let token = String(data: data, encoding: .utf8) else {
            return nil
        }
        return token
    }

    static func saveToken(_ token: String) {
        deleteToken()
        guard let data = token.data(using: .utf8) else { return }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: tokenKey,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        SecItemAdd(query as CFDictionary, nil)
    }

    static func deleteToken() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: tokenKey
        ]
        SecItemDelete(query as CFDictionary)
    }
}
