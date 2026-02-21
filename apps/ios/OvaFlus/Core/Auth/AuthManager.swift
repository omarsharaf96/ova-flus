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

    // Access token: prefer social tokens, then fall back to stored email/password token
    var accessToken: String? {
        if let tokens = socialTokens {
            return tokens.accessToken
        }
        return storedEmailPasswordToken
    }

    // Email/password tokens stored locally (transitional — Amplify will handle this)
    private var storedEmailPasswordToken: String? {
        let token: String? = LocalDataManager.shared.load(forKey: "email_auth_token")
        return token
    }

    private let apiClient: APIClient

    init(apiClient: APIClient = .shared) {
        self.apiClient = apiClient
        loadStoredSession()
    }

    // MARK: - Email/Password

    func signIn(email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }
        logger.info("Sign-in attempt for \(email)")
        // Email/password auth — currently requires Amplify SDK
        // After Amplify SDK is added, replace with:
        // let result = try await Amplify.Auth.signIn(username: email, password: password)
        // isAuthenticated = result.isSignedIn
        throw NSError(
            domain: "AuthError",
            code: -1,
            userInfo: [NSLocalizedDescriptionKey: "Email/password sign-in requires Amplify SDK. Please add Amplify SPM dependency."]
        )
    }

    func signUp(email: String, password: String, name: String) async throws {
        isLoading = true
        defer { isLoading = false }
        // TODO: Replace with Amplify.Auth.signUp after adding Amplify SPM
        throw NSError(
            domain: "AuthError",
            code: -1,
            userInfo: [NSLocalizedDescriptionKey: "Email/password sign-up requires Amplify SDK. Please add Amplify SPM dependency."]
        )
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
        LocalDataManager.shared.remove(forKey: "email_auth_token")
        LocalDataManager.shared.remove(forKey: "auth_tokens")
        // Amplify sign out (uncomment after adding Amplify SPM):
        // Task { _ = await Amplify.Auth.signOut() }
        isAuthenticated = false
        currentUser = nil
    }

    // MARK: - Session Management

    func checkSession() async {
        if socialTokens != nil {
            isAuthenticated = true
            await fetchProfile()
            return
        }
        // Check Amplify session (uncomment after adding Amplify SPM):
        // let session = try? await Amplify.Auth.fetchAuthSession()
        // isAuthenticated = session?.isSignedIn ?? false
        // if isAuthenticated { await fetchProfile() }
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
        // Check legacy email/password token
        if storedEmailPasswordToken != nil {
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
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.blue)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal)
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
                    .frame(height: 50)
                    .padding(.horizontal)

                    // Google Sign In (requires GoogleSignIn SPM)
                    Button {
                        Task { await signInWithGoogle() }
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "globe")
                                .foregroundStyle(.blue)
                            Text("Sign in with Google")
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(.white)
                        .foregroundStyle(.black)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(.gray.opacity(0.3)))
                    }
                    .padding(.horizontal)

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

                    Spacer().frame(height: 32)
                }
            }
        }
    }

    @MainActor
    private func signInWithGoogle() async {
        // Google Sign In requires GoogleSignIn SPM package.
        // After adding: https://github.com/google/GoogleSignIn-iOS (version ~7.0)
        // Uncomment the following:
        //
        // guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
        //       let rootVC = scene.windows.first?.rootViewController else { return }
        // do {
        //     let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootVC)
        //     if let idToken = result.user.idToken?.tokenString {
        //         try await authManager.signInWithGoogle(idToken: idToken)
        //     }
        // } catch {
        //     errorMessage = error.localizedDescription
        // }
        errorMessage = "Google Sign In: Add GoogleSignIn SPM package to enable"
    }
}
