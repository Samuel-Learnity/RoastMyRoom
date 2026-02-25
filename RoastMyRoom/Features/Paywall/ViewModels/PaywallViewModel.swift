import StoreKit
import Observation

@MainActor
@Observable
final class PaywallViewModel {
    private(set) var isLoading = false
    private(set) var isPurchasing = false
    var selectedProductID: String = "roomscore.weekly"
    var errorMessage: String?

    private let subscriptionService: SubscriptionService

    init(subscriptionService: SubscriptionService) {
        self.subscriptionService = subscriptionService
    }

    var products: [Product] { subscriptionService.products }
    var weeklyProduct: Product? { subscriptionService.weeklyProduct }
    var annualProduct: Product? { subscriptionService.annualProduct }
    var lifetimeProduct: Product? { subscriptionService.lifetimeProduct }

    var selectedProduct: Product? {
        products.first { $0.id == selectedProductID }
    }

    func loadProducts() async {
        isLoading = true
        await subscriptionService.loadProducts()
        isLoading = false
    }

    func purchase() async -> Bool {
        guard let product = selectedProduct else { return false }
        isPurchasing = true
        errorMessage = nil

        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()

        let success = await subscriptionService.purchase(product)

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

    var ctaText: String {
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
