import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Logo
            Image(systemName: "chart.bar.fill")
                .font(.system(size: 48))
                .foregroundStyle(.blue)
            Text("OvaFlus")
                .font(.title.weight(.bold))
            Text("Personal Finance Manager")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            // Login form
            VStack(spacing: 12) {
                TextField("Email", text: $email)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.emailAddress)

                SecureField("Password", text: $password)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.password)

                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                Button {
                    signIn()
                } label: {
                    if isLoading {
                        ProgressView()
                            .controlSize(.small)
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Sign In")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(email.isEmpty || password.isEmpty || isLoading)
                .keyboardShortcut(.return)
            }
            .frame(width: 280)

            // Sign up link
            HStack {
                Text("Don't have an account?")
                    .foregroundStyle(.secondary)
                Button("Sign Up") {
                    // TODO: Open sign up flow
                }
                .buttonStyle(.plain)
                .foregroundStyle(.blue)
            }
            .font(.caption)

            Spacer()
        }
        .padding()
    }

    private func signIn() {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                try await authManager.signIn(email: email, password: password)
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}
