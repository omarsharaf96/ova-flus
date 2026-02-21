import OSLog
import StoreKit
import SwiftUI

// MARK: - Product IDs
// Register all four in App Store Connect → Subscriptions
private enum ProductID {
    static let premiumMonthly = "com.ovaflus.app.premium.monthly"
    static let premiumYearly  = "com.ovaflus.app.premium.yearly"
    static let proMonthly     = "com.ovaflus.app.pro.monthly"
    static let proYearly      = "com.ovaflus.app.pro.yearly"

    static let all = [premiumMonthly, premiumYearly, proMonthly, proYearly]
}

// MARK: - Tier model

private struct SubscriptionTierInfo {
    let name: String
    let color: Color
    let icon: String
    let monthlyID: String
    let yearlyID: String
    let fallbackMonthly: String
    let fallbackYearly: String
    let features: [String]
}

private let tiers: [SubscriptionTierInfo] = [
    SubscriptionTierInfo(
        name: "Premium",
        color: .orange,
        icon: "star.fill",
        monthlyID: ProductID.premiumMonthly,
        yearlyID:  ProductID.premiumYearly,
        fallbackMonthly: "$10",
        fallbackYearly:  "$100",
        features: [
            "Unlimited budgets & categories",
            "Unlimited linked bank accounts",
            "Smart spending alerts",
            "CSV & PDF data export",
            "Priority support",
        ]
    ),
    SubscriptionTierInfo(
        name: "Pro",
        color: .purple,
        icon: "crown.fill",
        monthlyID: ProductID.proMonthly,
        yearlyID:  ProductID.proYearly,
        fallbackMonthly: "$20",
        fallbackYearly:  "$200",
        features: [
            "Everything in Premium",
            "Advanced analytics & insights",
            "Portfolio performance reports",
            "Custom budget categories",
            "Dedicated account manager",
        ]
    ),
]

// MARK: - ViewModel

@MainActor
final class UpgradePlanViewModel: ObservableObject {
    @Published var products: [Product] = []
    @Published var purchasedProductIDs: Set<String> = []
    @Published var selectedProductID: String = ProductID.premiumMonthly
    @Published var isPurchasing = false
    @Published var errorMessage: String?
    @Published var purchaseSuccess = false

    private let logger = Logger(subsystem: "com.ovaflus.app", category: "iap")
    private var transactionListener: Task<Void, Never>?

    init() {
        transactionListener = listenForTransactions()
        Task { await loadProducts() }
    }

    deinit { transactionListener?.cancel() }

    func loadProducts() async {
        do {
            products = try await Product.products(for: ProductID.all)
                .sorted { $0.price < $1.price }
            logger.info("Loaded \(self.products.count) products")
        } catch {
            logger.error("Failed to load products: \(error.localizedDescription)")
            errorMessage = "Could not load plans. Check your connection and try again."
        }
    }

    func purchase(_ productID: String) async {
        guard let product = products.first(where: { $0.id == productID }) else {
            errorMessage = "Plan unavailable. Please try again later."
            return
        }
        isPurchasing = true
        errorMessage = nil
        defer { isPurchasing = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                purchasedProductIDs.insert(product.id)
                purchaseSuccess = true
                logger.info("Purchase succeeded: \(product.id)")
            case .userCancelled:
                logger.info("Purchase cancelled by user")
            case .pending:
                logger.info("Purchase pending approval")
            @unknown default:
                break
            }
        } catch {
            errorMessage = "Purchase failed. Please try again."
            logger.error("Purchase failed: \(error.localizedDescription)")
        }
    }

    func restorePurchases() async {
        do {
            try await AppStore.sync()
            logger.info("Purchases restored")
        } catch {
            errorMessage = "Restore failed. Please try again."
            logger.error("Restore failed: \(error.localizedDescription)")
        }
    }

    func displayPrice(for productID: String, fallback: String) -> String {
        products.first { $0.id == productID }?.displayPrice ?? fallback
    }

    func savingsPercent(monthlyID: String, yearlyID: String) -> Int? {
        guard
            let m = products.first(where: { $0.id == monthlyID }),
            let y = products.first(where: { $0.id == yearlyID })
        else { return nil }
        let annual = m.price * Decimal(12)
        guard annual > 0 else { return nil }
        let pct = (annual - y.price) / annual * Decimal(100)
        return Int(truncating: NSDecimalNumber(decimal: pct))
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, _): throw StoreError.failedVerification
        case .verified(let value): return value
        }
    }

    private func listenForTransactions() -> Task<Void, Never> {
        Task(priority: .background) {
            for await result in StoreKit.Transaction.updates {
                if let transaction = try? result.payloadValue {
                    await transaction.finish()
                    _ = await MainActor.run {
                        self.purchasedProductIDs.insert(transaction.productID)
                    }
                }
            }
        }
    }
}

enum StoreError: Error { case failedVerification }

// MARK: - View

struct UpgradePlanView: View {
    @StateObject private var viewModel = UpgradePlanViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 6) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(.orange)
                    Text("Choose Your Plan")
                        .font(.title.bold())
                    Text("Upgrade to unlock the full OvaFlus experience")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 8)

                // Tier cards
                ForEach(tiers, id: \.name) { tier in
                    TierCardView(
                        tier: tier,
                        selectedProductID: $viewModel.selectedProductID,
                        monthlyPrice: viewModel.displayPrice(for: tier.monthlyID, fallback: tier.fallbackMonthly),
                        yearlyPrice:  viewModel.displayPrice(for: tier.yearlyID,  fallback: tier.fallbackYearly),
                        savingsPercent: viewModel.savingsPercent(monthlyID: tier.monthlyID, yearlyID: tier.yearlyID)
                    )
                }

                // Error
                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }

                // Subscribe button
                Button {
                    Task { await viewModel.purchase(viewModel.selectedProductID) }
                } label: {
                    Group {
                        if viewModel.isPurchasing {
                            ProgressView().tint(.white)
                        } else {
                            Text("Subscribe Now")
                                .font(.headline)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(selectedTierColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(viewModel.isPurchasing)

                // Restore + legal
                Button("Restore Purchases") {
                    Task { await viewModel.restorePurchases() }
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)

                Text("Subscriptions renew automatically. Cancel anytime in your Apple ID settings. By subscribing you agree to our Terms of Service and Privacy Policy.")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
            }
            .padding()
        }
        .navigationTitle("Plans")
        .navigationBarTitleDisplayMode(.inline)
        .alert("You're all set!", isPresented: $viewModel.purchaseSuccess) {
            Button("Let's Go") { dismiss() }
        } message: {
            Text("Your subscription is active. Enjoy all the features.")
        }
        .task { await viewModel.loadProducts() }
    }

    private var selectedTierColor: Color {
        tiers.first { tier in
            viewModel.selectedProductID == tier.monthlyID ||
            viewModel.selectedProductID == tier.yearlyID
        }?.color ?? .orange
    }
}

// MARK: - Tier Card

private struct TierCardView: View {
    let tier: SubscriptionTierInfo
    @Binding var selectedProductID: String
    let monthlyPrice: String
    let yearlyPrice: String
    let savingsPercent: Int?

    private var isAnySelected: Bool {
        selectedProductID == tier.monthlyID || selectedProductID == tier.yearlyID
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Tier header
            HStack(spacing: 10) {
                Image(systemName: tier.icon)
                    .foregroundStyle(tier.color)
                Text(tier.name)
                    .font(.title3.bold())
                    .foregroundStyle(tier.color)
            }

            // Features
            VStack(alignment: .leading, spacing: 10) {
                ForEach(tier.features, id: \.self) { feature in
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(tier.color)
                            .font(.subheadline)
                        Text(feature)
                            .font(.subheadline)
                    }
                }
            }

            Divider()

            // Billing options
            VStack(spacing: 10) {
                BillingOptionRow(
                    label: "Monthly",
                    price: monthlyPrice,
                    period: "per month",
                    badge: nil,
                    color: tier.color,
                    isSelected: selectedProductID == tier.monthlyID
                ) { selectedProductID = tier.monthlyID }

                BillingOptionRow(
                    label: "Yearly",
                    price: yearlyPrice,
                    period: "per year",
                    badge: savingsPercent.map { "Save \($0)%" },
                    color: tier.color,
                    isSelected: selectedProductID == tier.yearlyID
                ) { selectedProductID = tier.yearlyID }
            }
        }
        .padding()
        .background(isAnySelected ? tier.color.opacity(0.07) : Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isAnySelected ? tier.color : Color.clear, lineWidth: 2)
        )
    }
}

// MARK: - Billing Option Row

private struct BillingOptionRow: View {
    let label: String
    let price: String
    let period: String
    let badge: String?
    let color: Color
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .foregroundStyle(isSelected ? color : .secondary)
                HStack(spacing: 6) {
                    Text(label)
                        .font(.subheadline.bold())
                    if let badge {
                        Text(badge)
                            .font(.caption.bold())
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background(.green)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 1) {
                    Text(price)
                        .font(.subheadline.bold())
                    Text(period)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        UpgradePlanView()
    }
}
