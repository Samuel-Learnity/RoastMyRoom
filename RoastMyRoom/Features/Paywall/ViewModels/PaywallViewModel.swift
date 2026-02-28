import StoreKit
import Observation

@MainActor
@Observable
final class PaywallViewModel {
    enum PaywallTab: String, CaseIterable, Sendable {
        case points
        case subscription
    }

    private(set) var isLoading = false
    private(set) var isPurchasing = false
    var selectedTab: PaywallTab = .points
    var selectedProductID: String = "roomscore.weekly"
    var selectedPointsPackID: String = "roomscore.points.75"
    var errorMessage: String?

    private let subscriptionService: SubscriptionService

    init(subscriptionService: SubscriptionService, initialTab: PaywallTab = .points) {
        self.subscriptionService = subscriptionService
        self.selectedTab = initialTab
    }

    // MARK: - Subscription Accessors

    var products: [Product] { subscriptionService.products }
    var weeklyProduct: Product? { subscriptionService.weeklyProduct }
    var annualProduct: Product? { subscriptionService.annualProduct }
    var lifetimeProduct: Product? { subscriptionService.lifetimeProduct }

    var selectedProduct: Product? {
        products.first { $0.id == selectedProductID }
    }

    // MARK: - Points Accessors

    var pointsProducts: [Product] { subscriptionService.pointsProducts }
    var pointsBalance: Int { subscriptionService.pointsBalance }

    var selectedPointsProduct: Product? {
        pointsProducts.first { $0.id == selectedPointsPackID }
    }

    // MARK: - Load

    func loadProducts() async {
        isLoading = true
        await subscriptionService.loadProducts()
        isLoading = false
    }

    // MARK: - Purchase

    func purchase() async -> Bool {
        switch selectedTab {
        case .points:
            return await purchasePoints()
        case .subscription:
            return await purchaseSubscription()
        }
    }

    private func purchaseSubscription() async -> Bool {
        guard let product = selectedProduct else { return false }
        isPurchasing = true
        errorMessage = nil

        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()

        let success = await subscriptionService.purchase(product)

        if let error = subscriptionService.purchaseError {
            errorMessage = error
        }

        isPurchasing = false
        return success
    }

    private func purchasePoints() async -> Bool {
        guard let product = selectedPointsProduct else { return false }
        isPurchasing = true
        errorMessage = nil

        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()

        let success = await subscriptionService.purchasePoints(product)

        if let error = subscriptionService.purchaseError {
            errorMessage = error
        }

        isPurchasing = false
        return success
    }

    func restore() async {
        isLoading = true
        await subscriptionService.restore()
        isLoading = false
    }

    // MARK: - CTA Text

    var ctaText: String {
        switch selectedTab {
        case .points:
            guard let pack = PointsPack.pack(for: selectedPointsPackID) else {
                return String(localized: "paywall_cta_buy_points")
            }
            return String(localized: "paywall_cta_buy_points_count \(pack.points)")

        case .subscription:
            guard let product = selectedProduct else {
                return String(localized: "paywall_cta")
            }

            if product.id == "roomscore.lifetime" {
                return String(localized: "paywall_cta_lifetime")
            }

            if let subscription = product.subscription,
               let introOffer = subscription.introductoryOffer,
               introOffer.paymentMode == .freeTrial {
                return String(localized: "paywall_cta_trial")
            }

            return String(localized: "paywall_cta")
        }
    }
}
