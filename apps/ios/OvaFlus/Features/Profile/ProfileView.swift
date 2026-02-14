import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            List {
                // User info section
                Section {
                    HStack(spacing: 16) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 56))
                            .foregroundStyle(.blue)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(authManager.currentUser?.name ?? "User")
                                .font(.title3.bold())
                            Text(authManager.currentUser?.email ?? "")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }

                // Subscription tier
                Section("Subscription") {
                    HStack {
                        Label("Plan", systemImage: "crown.fill")
                        Spacer()
                        Text(authManager.currentUser?.subscriptionTier.rawValue.capitalized ?? "Free")
                            .foregroundStyle(.secondary)
                    }
                    NavigationLink {
                        Text("Upgrade Plan")
                    } label: {
                        Label("Upgrade to Premium", systemImage: "star.fill")
                            .foregroundStyle(.orange)
                    }
                }

                // Quick actions
                Section("Quick Actions") {
                    NavigationLink {
                        Text("Export Data View")
                    } label: {
                        Label("Export Data", systemImage: "square.and.arrow.up")
                    }
                    NavigationLink {
                        Text("Help & Support")
                    } label: {
                        Label("Help & Support", systemImage: "questionmark.circle")
                    }
                    NavigationLink {
                        Text("About")
                    } label: {
                        Label("About OvaFlus", systemImage: "info.circle")
                    }
                }

                // Settings
                Section {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Label("Settings", systemImage: "gearshape.fill")
                    }
                }

                // Sign out
                Section {
                    Button(role: .destructive) {
                        authManager.signOut()
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.forward")
                    }
                }
            }
            .navigationTitle("Profile")
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthManager())
}
