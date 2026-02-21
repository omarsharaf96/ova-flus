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
                        ZStack {
                            Circle()
                                .fill(.blue.opacity(0.15))
                                .frame(width: 64, height: 64)
                            Text(authManager.currentUser?.name.prefix(1).uppercased() ?? "?")
                                .font(.title.bold())
                                .foregroundStyle(.blue)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            if let name = authManager.currentUser?.name, !name.isEmpty {
                                Text(name)
                                    .font(.title3.bold())
                            } else {
                                Text("Loading...")
                                    .font(.title3.bold())
                                    .foregroundStyle(.secondary)
                                    .redacted(reason: .placeholder)
                            }
                            Text(authManager.currentUser?.email ?? "")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }

                // Quick actions
                Section("Quick Actions") {
                    NavigationLink(destination: GoalsView()) {
                        Label("Financial Goals", systemImage: "target")
                    }
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
