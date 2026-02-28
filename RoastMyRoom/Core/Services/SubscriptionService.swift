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
    private(set) var pointsProducts: [Product] = []
    private(set) var purchaseError: String?
    private(set) var _pointsBalance: Int = UserDefaults.standard.integer(forKey: "pointsBalance")

    private let productIDs: [String] = [
        "roomscore.weekly",
        "roomscore.annual",
        "roomscore.lifetime"
    ]

    private let pointsProductIDs: [String] = [
        "roomscore.points.10",
        "roomscore.points.35",
        "roomscore.points.75",
        "roomscore.points.200"
    ]

    private var transactionListener: Task<Void, Never>?

    private static let pointsInitializedKey = "pointsBalanceInitialized"

    init() {
        // Grant 2 free points on first launch
        if !UserDefaults.standard.bool(forKey: Self.pointsInitializedKey) {
            UserDefaults.standard.set(true, forKey: Self.pointsInitializedKey)
            if _pointsBalance == 0 {
                _pointsBalance = 2
                UserDefaults.standard.set(2, forKey: Self.pointsBalanceKey)
            }
        }
        transactionListener = listenForTransactions()
        Task { await checkSubscriptionStatus() }
    }

    func cancelListener() {
        transactionListener?.cancel()
    }

    // MARK: - Load Products

    func loadProducts() async {
        do {
            let allIDs = productIDs + pointsProductIDs
            let storeProducts = try await Product.products(for: allIDs)

            products = storeProducts
                .filter { $0.type == .autoRenewable || $0.type == .nonConsumable }
                .sorted { $0.price < $1.price }

            pointsProducts = storeProducts
                .filter { $0.type == .consumable }
                .sorted { $0.price < $1.price }
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

    // MARK: - Purchase Points

    func purchasePoints(_ product: Product) async -> Bool {
        purchaseError = nil
        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)

                if let pack = PointsPack.pack(for: transaction.productID) {
                    addPoints(pack.points)
                }

                await transaction.finish()
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

    // MARK: - Points Balance

    private static let pointsBalanceKey = "pointsBalance"

    var pointsBalance: Int { _pointsBalance }

    var hasPoints: Bool { _pointsBalance > 0 }

    private func addPoints(_ count: Int) {
        _pointsBalance += count
        UserDefaults.standard.set(_pointsBalance, forKey: Self.pointsBalanceKey)
    }

    func deductPoint() {
        guard _pointsBalance > 0 else { return }
        _pointsBalance -= 1
        UserDefaults.standard.set(_pointsBalance, forKey: Self.pointsBalanceKey)
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
        if hasFreeScansToday { return true }
        if hasPoints { return true }
        return false
    }

    private var hasFreeScansToday: Bool {
        let today = Calendar.current.startOfDay(for: Date())
        let lastDate = UserDefaults.standard.object(forKey: "lastScanDate") as? Date ?? .distantPast
        let lastScanDay = Calendar.current.startOfDay(for: lastDate)

        if today > lastScanDay { return true }

        let count = UserDefaults.standard.integer(forKey: "dailyScanCount")
        return count < 2
    }

    enum ScanPaymentSource: String, Sendable {
        case free, premium, points
    }

    /// Records a scan and returns the payment source used.
    /// Call AFTER successful API response.
    func recordScanWithSource() -> ScanPaymentSource {
        if isPremium { return .premium }

        if hasFreeScansToday {
            recordScan()
            return .free
        }

        deductPoint()
        return .points
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

    func debugSetPoints(_ count: Int) {
        _pointsBalance = count
        UserDefaults.standard.set(count, forKey: Self.pointsBalanceKey)
    }
    #endif

    // MARK: - Private

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached {
            for await result in Transaction.updates {
                if let transaction = try? self.checkVerified(result) {
                    if transaction.productType == .consumable {
                        if let pack = PointsPack.pack(for: transaction.productID) {
                            await MainActor.run {
                                self.addPoints(pack.points)
                            }
                        }
                    } else {
                        await self.checkSubscriptionStatus()
                    }
                    await transaction.finish()
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
