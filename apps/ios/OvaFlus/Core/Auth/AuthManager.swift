import Foundation
import SwiftUI

struct AuthTokens: Codable {
    let accessToken: String
    let refreshToken: String
    let expiresAt: Date
}

@MainActor
class AuthManager: ObservableObject {
    static let shared = AuthManager()

    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false

    var accessToken: String? {
        tokens?.accessToken
    }

    private var tokens: AuthTokens? {
        didSet {
            isAuthenticated = tokens != nil
            if let tokens {
                LocalDataManager.shared.save(tokens, forKey: "auth_tokens")
            } else {
                LocalDataManager.shared.remove(forKey: "auth_tokens")
            }
        }
    }

    private let apiClient: APIClient

    init(apiClient: APIClient = .shared) {
        self.apiClient = apiClient
        loadStoredTokens()
    }

    func signIn(email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }

        let response: AuthTokens = try await apiClient.request(.signIn(email: email, password: password))
        tokens = response
        await fetchProfile()
    }

    func signUp(email: String, password: String, name: String) async throws {
        isLoading = true
        defer { isLoading = false }

        let response: AuthTokens = try await apiClient.request(.signUp(email: email, password: password, name: name))
        tokens = response
        await fetchProfile()
    }

    func signOut() {
        tokens = nil
        currentUser = nil
        isAuthenticated = false
    }

    func refreshToken() async throws {
        guard let refreshToken = tokens?.refreshToken else {
            signOut()
            return
        }
        let response: AuthTokens = try await apiClient.request(.refreshToken(refreshToken: refreshToken))
        tokens = response
    }

    func setupBiometric() async -> Bool {
        let success = await BiometricAuth.shared.authenticate(reason: "Enable biometric authentication for OvaFlus")
        if success {
            UserDefaults.standard.set(true, forKey: "biometric_enabled")
        }
        return success
    }

    func authenticateWithBiometric() async -> Bool {
        guard UserDefaults.standard.bool(forKey: "biometric_enabled") else { return false }
        return await BiometricAuth.shared.authenticate(reason: "Sign in to OvaFlus")
    }

    private func loadStoredTokens() {
        if let storedTokens: AuthTokens = LocalDataManager.shared.load(forKey: "auth_tokens") {
            if storedTokens.expiresAt > Date() {
                tokens = storedTokens
                Task {
                    await fetchProfile()
                }
            } else {
                tokens = nil
            }
        }
    }

    private func fetchProfile() async {
        do {
            currentUser = try await apiClient.request(.getProfile)
        } catch {
            // Profile fetch failed but user is still authenticated
        }
    }
}

// Placeholder for LoginView referenced in OvaFlusApp
struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var name = ""
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "chart.bar.doc.horizontal.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.blue)

                Text("OvaFlus")
                    .font(.largeTitle.bold())

                Text("Your personal finance companion")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                VStack(spacing: 16) {
                    if isSignUp {
                        TextField("Full Name", text: $name)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(.name)
                    }
                    TextField("Email", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    SecureField("Password", text: $password)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(isSignUp ? .newPassword : .password)
                }
                .padding(.horizontal)

                if let errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                Button {
                    Task {
                        do {
                            if isSignUp {
                                try await authManager.signUp(email: email, password: password, name: name)
                            } else {
                                try await authManager.signIn(email: email, password: password)
                            }
                        } catch {
                            errorMessage = "Authentication failed. Please try again."
                        }
                    }
                } label: {
                    Text(isSignUp ? "Sign Up" : "Sign In")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)
                .disabled(authManager.isLoading)

                Button {
                    Task {
                        let success = await authManager.authenticateWithBiometric()
                        if !success {
                            errorMessage = "Biometric authentication failed"
                        }
                    }
                } label: {
                    Label("Sign in with Face ID", systemImage: "faceid")
                }

                Button {
                    isSignUp.toggle()
                } label: {
                    Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                        .font(.subheadline)
                }

                // Dev bypass
                VStack(spacing: 8) {
                    HStack {
                        Rectangle().frame(height: 1).foregroundStyle(.quaternary)
                        Text("DEV ONLY").font(.caption2).foregroundStyle(.tertiary)
                        Rectangle().frame(height: 1).foregroundStyle(.quaternary)
                    }

                    Button {
                        authManager.isAuthenticated = true
                    } label: {
                        Text("Bypass Login (Dev)")
                            .font(.subheadline.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.yellow.opacity(0.15))
                            .foregroundStyle(Color(red: 0.71, green: 0.40, blue: 0.04))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.yellow.opacity(0.6), style: StrokeStyle(lineWidth: 1, dash: [4]))
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
                .padding(.horizontal)

                Spacer()
            }
        }
    }
}
