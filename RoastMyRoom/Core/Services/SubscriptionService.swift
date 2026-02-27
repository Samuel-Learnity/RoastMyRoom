import StoreKit
import Observation

@MainActor
@Observable
final class SubscriptionService {
    #if DEBUG
    private(set) var isPremium = true
    #else
    private(set) var isPremium = false
    #endif
    private(set) var products: [Product] = []
    private(set) var purchaseError: String?

    private let productIDs: [String] = [
        "roomscore.weekly",
        "roomscore.annual",
        "roomscore.lifetime"
    ]

    private var transactionListener: Task<Void, Never>?

    init() {
        transactionListener = listenForTransactions()
        Task { await checkSubscriptionStatus() }
    }

    func cancelListener() {
        transactionListener?.cancel()
    }

    // MARK: - Load Products

    func loadProducts() async {
        do {
            let storeProducts = try await Product.products(for: productIDs)
            products = storeProducts.sorted { $0.price < $1.price }
        } catch {
            purchaseError = error.localizedDescription
        }
    }

    // MARK: - Purchase

    func purchase(_ product: Product) async -> Bool {
        purchaseError = nil
        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                await checkSubscriptionStatus()
                return true

            case .userCancelled:
                return false

            case .pending:
                return false

            @unknown default:
                return false
            }
        } catch {
            purchaseError = error.localizedDescription
            return false
        }
    }

    // MARK: - Restore

    func restore() async {
        purchaseError = nil
        do {
            try await AppStore.sync()
            await checkSubscriptionStatus()
        } catch {
            purchaseError = error.localizedDescription
        }
    }

    // MARK: - Status Check

    func checkSubscriptionStatus() async {
        #if DEBUG
        // In debug, keep premium enabled unless explicitly toggled off
        return
        #else
        var hasActiveSubscription = false

        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result) {
                if transaction.revocationDate == nil {
                    hasActiveSubscription = true
                    break
                }
            }
        }

        isPremium = hasActiveSubscription
        #endif
    }

    // MARK: - Helpers

    var weeklyProduct: Product? {
        products.first { $0.id == "roomscore.weekly" }
    }

    var annualProduct: Product? {
        products.first { $0.id == "roomscore.annual" }
    }

    var lifetimeProduct: Product? {
        products.first { $0.id == "roomscore.lifetime" }
    }

    // MARK: - Scan Limits

    var dailyScanLimit: Int { isPremium ? .max : 2 }

    var canScan: Bool {
        if isPremium { return true }

        let today = Calendar.current.startOfDay(for: Date())
        let lastDate = UserDefaults.standard.object(forKey: "lastScanDate") as? Date ?? .distantPast
        let lastScanDay = Calendar.current.startOfDay(for: lastDate)

        if today > lastScanDay {
            return true // New day, reset
        }

        let count = UserDefaults.standard.integer(forKey: "dailyScanCount")
        return count < 2
    }

    func recordScan() {
        let today = Calendar.current.startOfDay(for: Date())
        let lastDate = UserDefaults.standard.object(forKey: "lastScanDate") as? Date ?? .distantPast
        let lastScanDay = Calendar.current.startOfDay(for: lastDate)

        if today > lastScanDay {
            UserDefaults.standard.set(1, forKey: "dailyScanCount")
            UserDefaults.standard.set(today, forKey: "lastScanDate")
        } else {
            let count = UserDefaults.standard.integer(forKey: "dailyScanCount")
            UserDefaults.standard.set(count + 1, forKey: "dailyScanCount")
        }
    }

    var remainingScansToday: Int {
        if isPremium { return .max }

        let today = Calendar.current.startOfDay(for: Date())
        let lastDate = UserDefaults.standard.object(forKey: "lastScanDate") as? Date ?? .distantPast
        let lastScanDay = Calendar.current.startOfDay(for: lastDate)

        if today > lastScanDay { return 2 }

        let count = UserDefaults.standard.integer(forKey: "dailyScanCount")
        return max(0, 2 - count)
    }

    // MARK: - Debug

    #if DEBUG
    func debugTogglePremium() {
        isPremium.toggle()
    }
    #endif

    // MARK: - Private

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached {
            for await result in Transaction.updates {
                if let transaction = try? self.checkVerified(result) {
                    await transaction.finish()
                    await self.checkSubscriptionStatus()
                }
            }
        }
    }

    private nonisolated func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.verificationFailed
        case .verified(let safe):
            return safe
        }
    }
}

enum StoreError: Error {
    case verificationFailed
}
