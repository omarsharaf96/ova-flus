import AuthenticationServices
import Foundation
import OSLog
import SwiftUI

// MARK: - Cognito Token Response

struct CognitoTokenResponse: Codable {
    let accessToken: String
    let idToken: String
    let refreshToken: String
    let expiresIn: Int

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case idToken = "id_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
    }
}

// MARK: - Auth Error

enum AuthError: Error {
    case notConfigured
    case missingToken
    case unknown(String)
}

// MARK: - AuthManager

@MainActor
class AuthManager: ObservableObject {
    static let shared = AuthManager()
    private let logger = Logger(subsystem: "com.ovaflus.app", category: "auth")

    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?

    // Social sign-in tokens (Apple/Google flow)
    private var socialTokens: CognitoTokenResponse? {
        didSet {
            if let tokens = socialTokens {
                LocalDataManager.shared.save(tokens, forKey: "social_cognito_tokens")
            } else {
                LocalDataManager.shared.remove(forKey: "social_cognito_tokens")
            }
        }
    }

    // Email/password tokens (Cognito via backend)
    private var emailTokens: CognitoTokenResponse? {
        didSet {
            if let tokens = emailTokens {
                LocalDataManager.shared.save(tokens, forKey: "email_cognito_tokens")
            } else {
                LocalDataManager.shared.remove(forKey: "email_cognito_tokens")
            }
        }
    }

    // Access token: prefer social tokens, then email tokens
    var accessToken: String? {
        if let tokens = socialTokens {
            return tokens.accessToken
        }
        if let tokens = emailTokens {
            return tokens.accessToken
        }
        return nil
    }

    private let apiClient: APIClient

    private init(apiClient: APIClient = .shared) {
        self.apiClient = apiClient
        loadStoredSession()
    }

    // MARK: - Email/Password

    @Published var needsConfirmation = false
    @Published var pendingConfirmationEmail: String?
    var pendingPassword: String?

    func signIn(email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }
        logger.info("Sign-in attempt for \(email)")
        do {
            let response: CognitoTokenResponse = try await apiClient.request(
                .emailSignIn(email: email, password: password)
            )
            emailTokens = response
            isAuthenticated = true
            await fetchProfile()
            logger.info("Email sign-in succeeded")
        } catch {
            logger.error("Email sign-in failed: \(error.localizedDescription)")
            throw error
        }
    }

    func signUp(email: String, password: String, name: String) async throws {
        isLoading = true
        defer { isLoading = false }
        logger.info("Sign-up attempt for \(email)")
        do {
            // Backend initiates sign-up; user must confirm via code
            let _: [String: String] = try await apiClient.request(
                .emailSignUp(email: email, password: password, name: name)
            )
            pendingConfirmationEmail = email
            pendingPassword = password
            needsConfirmation = true
            logger.info("Sign-up succeeded, awaiting confirmation")
        } catch {
            logger.error("Email sign-up failed: \(error.localizedDescription)")
            throw error
        }
    }

    func confirmSignUp(email: String, code: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }
        logger.info("Confirming sign-up for \(email)")
        do {
            let _: [String: String] = try await apiClient.request(
                .emailConfirmSignUp(email: email, code: code)
            )
            needsConfirmation = false
            pendingConfirmationEmail = nil
            logger.info("Confirmation succeeded for \(email), signing in automatically")
            // Auto sign-in after confirmation
            try await signIn(email: email, password: password)
        } catch {
            logger.error("Confirmation failed: \(error.localizedDescription)")
            throw error
        }
    }

    // MARK: - Apple Sign In

    func signInWithApple(credential: ASAuthorizationAppleIDCredential) async throws {
        guard let tokenData = credential.identityToken,
              let identityToken = String(data: tokenData, encoding: .utf8) else {
            throw NSError(
                domain: "AuthError",
                code: -2,
                userInfo: [NSLocalizedDescriptionKey: "Missing Apple identity token"]
            )
        }
        isLoading = true
        defer { isLoading = false }
        logger.info("Apple Sign In: exchanging identity token")
        do {
            let response: CognitoTokenResponse = try await apiClient.request(
                .appleSignIn(identityToken: identityToken)
            )
            socialTokens = response
            isAuthenticated = true
            await fetchProfile()
            logger.info("Apple Sign In succeeded")
        } catch {
            logger.error("Apple Sign In failed: \(error.localizedDescription)")
            throw error
        }
    }

    // MARK: - Google Sign In

    func signInWithGoogle(idToken: String) async throws {
        isLoading = true
        defer { isLoading = false }
        logger.info("Google Sign In: exchanging ID token")
        do {
            let response: CognitoTokenResponse = try await apiClient.request(
                .googleSignIn(idToken: idToken)
            )
            socialTokens = response
            isAuthenticated = true
            await fetchProfile()
            logger.info("Google Sign In succeeded")
        } catch {
            logger.error("Google Sign In failed: \(error.localizedDescription)")
            throw error
        }
    }

    // MARK: - Sign Out

    func signOut() {
        logger.info("User signed out")
        socialTokens = nil
        emailTokens = nil
        isAuthenticated = false
        currentUser = nil
        pendingPassword = nil
    }

    // MARK: - Session Management

    func checkSession() async {
        if socialTokens != nil || emailTokens != nil {
            isAuthenticated = true
            await fetchProfile()
            return
        }
        isAuthenticated = false
    }

    // MARK: - Biometric

    func setupBiometric() async -> Bool {
        logger.info("Setting up biometric authentication")
        let success = await BiometricAuth.shared.authenticate(reason: "Enable biometric authentication for OvaFlus")
        if success {
            UserDefaults.standard.set(true, forKey: "biometric_enabled")
            logger.info("Biometric authentication enabled")
        }
        return success
    }

    func authenticateWithBiometric() async -> Bool {
        guard UserDefaults.standard.bool(forKey: "biometric_enabled") else { return false }
        return await BiometricAuth.shared.authenticate(reason: "Sign in to OvaFlus")
    }

    // MARK: - Private

    private func loadStoredSession() {
        // Try to load stored social tokens
        if let tokens: CognitoTokenResponse = LocalDataManager.shared.load(forKey: "social_cognito_tokens") {
            socialTokens = tokens
            isAuthenticated = true
            Task { await fetchProfile() }
            return
        }
        // Check stored email tokens
        if let tokens: CognitoTokenResponse = LocalDataManager.shared.load(forKey: "email_cognito_tokens") {
            emailTokens = tokens
            isAuthenticated = true
            Task { await fetchProfile() }
        }
    }

    private func fetchProfile() async {
        do {
            currentUser = try await apiClient.request(.getProfile)
            logger.info("Profile loaded for user \(self.currentUser?.id ?? "unknown")")
        } catch {
            logger.error("Profile fetch failed: \(error.localizedDescription)")
        }
    }
}

// MARK: - LoginView

struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var name = ""
    @State private var confirmationCode = ""
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Spacer().frame(height: 32)

                    Image(systemName: "chart.bar.doc.horizontal.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(.blue)

                    Text("OvaFlus")
                        .font(.largeTitle.bold())

                    Text("Your personal finance companion")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if authManager.needsConfirmation {
                        // Confirmation code entry
                        VStack(spacing: 16) {
                            Text("Check your email for a confirmation code")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)

                            TextField("Confirmation Code", text: $confirmationCode)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.numberPad)
                                .textContentType(.oneTimeCode)
                        }
                        .padding(.horizontal)

                        if let errorMessage {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundStyle(.red)
                                .padding(.horizontal)
                        }

                        Button {
                            Task {
                                do {
                                    try await authManager.confirmSignUp(
                                        email: authManager.pendingConfirmationEmail ?? email,
                                        code: confirmationCode,
                                        password: authManager.pendingPassword ?? password
                                    )
                                } catch {
                                    errorMessage = error.localizedDescription
                                }
                            }
                        } label: {
                            Text("Confirm")
                                .font(.headline)
                                .frame(maxWidth: 320)
                                .padding()
                                .background(.blue)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .disabled(authManager.isLoading || confirmationCode.isEmpty)

                        Button {
                            authManager.needsConfirmation = false
                            authManager.pendingConfirmationEmail = nil
                            authManager.pendingPassword = nil
                            confirmationCode = ""
                            errorMessage = nil
                        } label: {
                            Text("Back to Sign In")
                                .font(.subheadline)
                        }
                    } else {
                        // Email/Password Section
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
                                .padding(.horizontal)
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
                                    errorMessage = error.localizedDescription
                                }
                            }
                        } label: {
                            Text(isSignUp ? "Sign Up" : "Sign In")
                                .font(.headline)
                                .frame(maxWidth: 320)
                                .padding()
                                .background(.blue)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .disabled(authManager.isLoading)

                        // Divider
                        HStack {
                            Rectangle().frame(height: 1).foregroundStyle(.quaternary)
                            Text("or").font(.subheadline).foregroundStyle(.secondary)
                            Rectangle().frame(height: 1).foregroundStyle(.quaternary)
                        }
                        .padding(.horizontal)

                        // Sign In with Apple
                        SignInWithAppleButton(.signIn) { request in
                            request.requestedScopes = [.email, .fullName]
                        } onCompletion: { result in
                            switch result {
                            case .success(let auth):
                                if let appleCredential = auth.credential as? ASAuthorizationAppleIDCredential {
                                    Task {
                                        do {
                                            try await authManager.signInWithApple(credential: appleCredential)
                                        } catch {
                                            errorMessage = "Apple Sign In failed: \(error.localizedDescription)"
                                        }
                                    }
                                }
                            case .failure(let error):
                                errorMessage = "Apple Sign In cancelled: \(error.localizedDescription)"
                            }
                        }
                        .signInWithAppleButtonStyle(.black)
                        .frame(width: 280, height: 44)

                        // Google Sign In — Coming soon (requires Google Client ID configuration)
                        HStack(spacing: 12) {
                            Image(systemName: "globe")
                                .foregroundStyle(.gray)
                            Text("Sign in with Google — Coming soon")
                                .fontWeight(.medium)
                        }
                        .frame(width: 280, height: 44)
                        .background(Color(.systemGray6))
                        .foregroundStyle(.gray)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(.gray.opacity(0.3)))

                        Button {
                            isSignUp.toggle()
                            errorMessage = nil
                        } label: {
                            Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                                .font(.subheadline)
                        }

                        // Biometric
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
                    }

                    Spacer().frame(height: 32)
                }
            }
        }
    }
}
