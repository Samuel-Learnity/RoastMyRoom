import StoreKit
import Observation

@MainActor
@Observable
final class PaywallViewModel: Identifiable {
    let id = UUID()
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

    private(set) var showAuthPrompt = false

    private let subscriptionService: SubscriptionServiceProtocol
    private let authService: AuthServiceProtocol?
    private let analyticsService: AnalyticsServiceProtocol

    init(subscriptionService: SubscriptionServiceProtocol, authService: AuthServiceProtocol? = nil, initialTab: PaywallTab = .points, analyticsService: AnalyticsServiceProtocol = AnalyticsService()) {
        self.subscriptionService = subscriptionService
        self.authService = authService
        self.selectedTab = initialTab
        self.analyticsService = analyticsService
    }

    // MARK: - Subscription Accessors

    var products: [Product] { subscriptionService.products }
    var weeklyProduct: Product? { subscriptionService.weeklyProduct }
    var annualProduct: Product? { subscriptionService.annualProduct }
    var lifetimeProduct: Product? { subscriptionService.lifetimeProduct }
    var activeProductID: String? { subscriptionService.activeProductID }

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
        analyticsService.track(.purchaseStarted(productId: product.id, productType: "subscription"))

        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()

        let success = await subscriptionService.purchase(product)

        if let error = subscriptionService.purchaseError {
            errorMessage = error
            analyticsService.track(.purchaseError(productId: product.id, error: error))
        } else if success {
            analyticsService.track(.purchaseSuccess(productId: product.id, productType: "subscription", price: product.displayPrice))
        } else {
            analyticsService.track(.purchaseCancelled(productId: product.id))
        }

        isPurchasing = false
        return success
    }

    private func purchasePoints() async -> Bool {
        guard let product = selectedPointsProduct else { return false }
        isPurchasing = true
        errorMessage = nil
        analyticsService.track(.purchaseStarted(productId: product.id, productType: "points"))

        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()

        let success = await subscriptionService.purchasePoints(product)

        if let error = subscriptionService.purchaseError {
            errorMessage = error
            analyticsService.track(.purchaseError(productId: product.id, error: error))
        } else if success {
            analyticsService.track(.purchaseSuccess(productId: product.id, productType: "points", price: product.displayPrice))

            // Show auth prompt if not signed in
            if authService?.isAuthenticated != true {
                showAuthPrompt = true
                analyticsService.track(.authPromptShown(source: "post_purchase"))
            }
        } else {
            analyticsService.track(.purchaseCancelled(productId: product.id))
        }

        isPurchasing = false
        return success
    }

    func restore() async {
        analyticsService.track(.paywallRestoreClicked())
        isLoading = true
        await subscriptionService.restore()
        isLoading = false
    }

    func trackTabSwitch() {
        analyticsService.track(.paywallTabSwitched(tab: selectedTab.rawValue))
    }

    func trackCtaClicked() {
        let productId: String
        switch selectedTab {
        case .points:
            productId = selectedPointsPackID
        case .subscription:
            productId = selectedProductID
        }
        analyticsService.track(.paywallCtaClicked(tab: selectedTab.rawValue, productId: productId))
    }

    func trackPaywallClosed() {
        analyticsService.track(.paywallClosed(tab: selectedTab.rawValue))
    }

    func dismissAuthPrompt() {
        showAuthPrompt = false
        analyticsService.track(.authPromptDismissed())
    }

    func signInFromPrompt() async {
        analyticsService.track(.authSignInStarted())
        do {
            try await authService?.signInWithApple()
            analyticsService.track(.authSignInSuccess())
            subscriptionService.grantSignUpBonusIfNeeded()
            if let auth = authService {
                await subscriptionService.syncPointsWithServer(authService: auth)
            }
        } catch {
            analyticsService.track(.authSignInError(error: error.localizedDescription))
        }
        showAuthPrompt = false
    }

    // MARK: - CTA Text

    var ctaText: String {
        switch selectedTab {
        case .points:
            // Only show specific count when the product is actually available
            guard let _ = selectedPointsProduct,
                  let pack = PointsPack.pack(for: selectedPointsPackID) else {
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
