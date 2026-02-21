import SwiftUI
import SwiftData

struct BankAccountsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \LinkedBankAccountModel.linkedAt, order: .reverse) var accounts: [LinkedBankAccountModel]

    @StateObject private var plaidService = PlaidService.shared
    @State private var showPlaidLink = false
    @State private var linkToken: String?
    @State private var showError = false

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    var body: some View {
        NavigationStack {
            List {
                if accounts.isEmpty {
                    Section {
                        VStack(spacing: 12) {
                            Image(systemName: "building.columns")
                                .font(.system(size: 40))
                                .foregroundStyle(.secondary)
                            Text("No Linked Accounts")
                                .font(.headline)
                            Text("Link a bank account to automatically import transactions.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                    }
                } else {
                    Section("Linked Accounts") {
                        ForEach(accounts) { account in
                            AccountRowView(account: account, dateFormatter: dateFormatter)
                        }
                        .onDelete(perform: unlinkAccounts)
                    }

                    Section {
                        Button {
                            Task { await syncNow() }
                        } label: {
                            HStack {
                                Label("Sync Now", systemImage: "arrow.clockwise")
                                Spacer()
                                if plaidService.isSyncing {
                                    ProgressView()
                                }
                            }
                        }
                        .disabled(plaidService.isSyncing)
                    }
                }
            }
            .navigationTitle("Bank Accounts")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task { await openPlaidLink() }
                    } label: {
                        Label("Link Account", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showPlaidLink) {
                if let token = linkToken {
                    PlaidLinkView(
                        linkToken: token,
                        onSuccess: { publicToken, metadata in
                            showPlaidLink = false
                            Task {
                                let accountsData = metadata.accounts.map { acct -> [String: String] in
                                    [
                                        "id": acct.id,
                                        "name": acct.name,
                                        "subtype": String(describing: acct.subtype),
                                        "mask": acct.mask ?? ""
                                    ]
                                }
                                try? await plaidService.exchangePublicToken(
                                    publicToken,
                                    institutionId: metadata.institution.id,
                                    institutionName: metadata.institution.name,
                                    accounts: accountsData,
                                    context: modelContext
                                )
                            }
                        },
                        onExit: { _ in
                            showPlaidLink = false
                        }
                    )
                    .ignoresSafeArea()
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(plaidService.errorMessage ?? "An error occurred.")
            }
            .onChange(of: plaidService.errorMessage) { _, message in
                showError = message != nil
            }
        }
    }

    // MARK: - Actions

    private func openPlaidLink() async {
        do {
            linkToken = try await plaidService.createLinkToken()
            showPlaidLink = true
        } catch {
            plaidService.errorMessage = error.localizedDescription
        }
    }

    private func syncNow() async {
        await plaidService.syncTransactions(context: modelContext)
    }

    private func unlinkAccounts(at offsets: IndexSet) {
        for offset in offsets {
            let account = accounts[offset]
            Task {
                await plaidService.unlinkAccount(account, context: modelContext)
            }
        }
    }
}

// MARK: - Account Row

private struct AccountRowView: View {
    let account: LinkedBankAccountModel
    let dateFormatter: DateFormatter

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(account.institutionName)
                        .font(.subheadline.bold())
                    Text("\(account.accountName) •••• \(account.mask)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(account.accountType.capitalized)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.blue.opacity(0.1))
                    .foregroundStyle(.blue)
                    .clipShape(Capsule())
            }
            if let syncedAt = account.lastSyncedAt {
                Text("Last synced: \(dateFormatter.string(from: syncedAt))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else {
                Text("Never synced")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
