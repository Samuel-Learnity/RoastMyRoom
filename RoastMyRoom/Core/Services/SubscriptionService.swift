import StoreKit
import Observation

// MARK: - Protocol

@MainActor
protocol SubscriptionServiceProtocol: AnyObject, Observable {
    var isPremium: Bool { get }
    var activeProductID: String? { get }
    var products: [Product] { get }
    var pointsProducts: [Product] { get }
    var purchaseError: String? { get }
    var pointsBalance: Int { get }
    var hasPoints: Bool { get }
    var willCostPoint: Bool { get }
    var weeklyProduct: Product? { get }
    var annualProduct: Product? { get }
    var lifetimeProduct: Product? { get }
    var canScan: Bool { get }
    var remainingScansToday: Int { get }
    var dailyScanLimit: Int { get }
    var signUpBonusClaimed: Bool { get }

    func loadProducts() async
    func purchase(_ product: Product) async -> Bool
    func purchasePoints(_ product: Product) async -> Bool
    func restore() async
    func checkSubscriptionStatus() async
    func deductPoint()
    func recordScanWithSource() -> SubscriptionService.ScanPaymentSource
    func recordScan()
    @discardableResult func grantSignUpBonusIfNeeded() -> Bool
    func cancelListener()
    func syncPointsWithServer(authService: AuthServiceProtocol) async
    func pushPointsToServer(authService: AuthServiceProtocol)

    #if DEBUG
    func debugTogglePremium()
    func debugSetPoints(_ count: Int)
    func debugAddLaunchPoints()
    #endif
}

// MARK: - Implementation

@MainActor
@Observable
final class SubscriptionService: SubscriptionServiceProtocol {
    #if DEBUG
    private(set) var isPremium = true
    #else
    private(set) var isPremium = false
    #endif
    private(set) var activeProductID: String?
    private(set) var products: [Product] = []
    private(set) var pointsProducts: [Product] = []
    private(set) var purchaseError: String?
    private(set) var _pointsBalance: Int = 0

    private let keychain: KeychainServiceProtocol
    private let supabaseBaseURL: String
    private let supabaseAnonKey: String

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

    // MARK: - Keychain Keys

    private static let pointsBalanceKey = "pointsBalance"
    private static let pointsInitializedKey = "pointsBalanceInitialized"
    private static let signInBonusGrantedKey = "signInBonusGranted"
    private static let dailyScanCountKey = "dailyScanCount"
    private static let lastScanDateKey = "lastScanDate"

    // MARK: - Init

    init(
        keychainService: KeychainServiceProtocol = KeychainService(),
        supabaseBaseURL: String = "",
        supabaseAnonKey: String = ""
    ) {
        self.keychain = keychainService
        self.supabaseBaseURL = supabaseBaseURL
        self.supabaseAnonKey = supabaseAnonKey

        migrateFromUserDefaults()

        _pointsBalance = keychain.getInt(forKey: Self.pointsBalanceKey) ?? 0

        // Grant 4 free points on first launch
        if keychain.getBool(forKey: Self.pointsInitializedKey) != true {
            keychain.set(true, forKey: Self.pointsInitializedKey)
            if _pointsBalance == 0 {
                _pointsBalance = 4
                keychain.set(4, forKey: Self.pointsBalanceKey)
            }
        }

        transactionListener = listenForTransactions()
        Task { await checkSubscriptionStatus() }
    }

    func cancelListener() {
        transactionListener?.cancel()
    }

    // MARK: - Migration from UserDefaults

    private func migrateFromUserDefaults() {
        let defaults = UserDefaults.standard

        // Migrate pointsBalanceInitialized
        if defaults.object(forKey: Self.pointsInitializedKey) != nil
            && keychain.getBool(forKey: Self.pointsInitializedKey) == nil {
            keychain.set(defaults.bool(forKey: Self.pointsInitializedKey), forKey: Self.pointsInitializedKey)
            defaults.removeObject(forKey: Self.pointsInitializedKey)
        }

        // Migrate pointsBalance
        if defaults.object(forKey: Self.pointsBalanceKey) != nil
            && keychain.getInt(forKey: Self.pointsBalanceKey) == nil {
            keychain.set(defaults.integer(forKey: Self.pointsBalanceKey), forKey: Self.pointsBalanceKey)
            defaults.removeObject(forKey: Self.pointsBalanceKey)
        }

        // Migrate dailyScanCount
        if defaults.object(forKey: Self.dailyScanCountKey) != nil
            && keychain.getInt(forKey: Self.dailyScanCountKey) == nil {
            keychain.set(defaults.integer(forKey: Self.dailyScanCountKey), forKey: Self.dailyScanCountKey)
            defaults.removeObject(forKey: Self.dailyScanCountKey)
        }

        // Migrate lastScanDate
        if let date = defaults.object(forKey: Self.lastScanDateKey) as? Date,
           keychain.getDate(forKey: Self.lastScanDateKey) == nil {
            keychain.set(date, forKey: Self.lastScanDateKey)
            defaults.removeObject(forKey: Self.lastScanDateKey)
        }
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

    var pointsBalance: Int { _pointsBalance }

    var hasPoints: Bool { _pointsBalance > 0 }

    /// Whether the next scan will cost 1 point (not premium, no free scans left, has points).
    var willCostPoint: Bool {
        !isPremium && !hasFreeScansToday && hasPoints
    }

    private func addPoints(_ count: Int) {
        _pointsBalance += count
        keychain.set(_pointsBalance, forKey: Self.pointsBalanceKey)
    }

    func deductPoint() {
        guard _pointsBalance > 0 else { return }
        _pointsBalance -= 1
        keychain.set(_pointsBalance, forKey: Self.pointsBalanceKey)
    }

    /// Whether the sign-up bonus has already been claimed.
    var signUpBonusClaimed: Bool {
        keychain.getBool(forKey: Self.signInBonusGrantedKey) == true
    }

    /// Grants 4 bonus points on first sign-up. Returns true if bonus was granted.
    @discardableResult
    func grantSignUpBonusIfNeeded() -> Bool {
        guard keychain.getBool(forKey: Self.signInBonusGrantedKey) != true else { return false }
        keychain.set(true, forKey: Self.signInBonusGrantedKey)
        addPoints(4)
        return true
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
        // In debug, simulate weekly subscription if premium with no real entitlement
        if isPremium && activeProductID == nil {
            activeProductID = "roomscore.weekly"
        }
        return
        #else
        var hasActiveSubscription = false
        var foundProductID: String?

        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result) {
                if transaction.revocationDate == nil {
                    hasActiveSubscription = true
                    foundProductID = transaction.productID
                    break
                }
            }
        }

        isPremium = hasActiveSubscription
        activeProductID = foundProductID
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
        let lastDate = keychain.getDate(forKey: Self.lastScanDateKey) ?? .distantPast
        let lastScanDay = Calendar.current.startOfDay(for: lastDate)

        if today > lastScanDay { return true }

        let count = keychain.getInt(forKey: Self.dailyScanCountKey) ?? 0
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
        let lastDate = keychain.getDate(forKey: Self.lastScanDateKey) ?? .distantPast
        let lastScanDay = Calendar.current.startOfDay(for: lastDate)

        if today > lastScanDay {
            keychain.set(1, forKey: Self.dailyScanCountKey)
            keychain.set(today, forKey: Self.lastScanDateKey)
        } else {
            let count = keychain.getInt(forKey: Self.dailyScanCountKey) ?? 0
            keychain.set(count + 1, forKey: Self.dailyScanCountKey)
        }
    }

    var remainingScansToday: Int {
        if isPremium { return .max }

        let today = Calendar.current.startOfDay(for: Date())
        let lastDate = keychain.getDate(forKey: Self.lastScanDateKey) ?? .distantPast
        let lastScanDay = Calendar.current.startOfDay(for: lastDate)

        if today > lastScanDay { return 2 }

        let count = keychain.getInt(forKey: Self.dailyScanCountKey) ?? 0
        return max(0, 2 - count)
    }

    // MARK: - Server Sync

    /// Syncs points with server when user is authenticated.
    /// Uses max(local, remote) merge strategy.
    func syncPointsWithServer(authService: AuthServiceProtocol) async {
        guard authService.isAuthenticated,
              let userId = authService.currentUserId,
              let accessToken = authService.accessToken else { return }

        let baseURL = supabaseBaseURL
        let anonKey = supabaseAnonKey

        do {
            // Read remote balance
            guard let url = URL(string: "\(baseURL)/rest/v1/user_points?user_id=eq.\(userId)&select=balance") else { return }

            var request = URLRequest(url: url)
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            request.setValue(anonKey, forHTTPHeaderField: "apikey")

            let (data, _) = try await URLSession.shared.data(for: request)
            let rows = try JSONDecoder().decode([[String: Int]].self, from: data)
            let remoteBalance = rows.first?["balance"]

            let localBalance = _pointsBalance
            let mergedBalance = max(localBalance, remoteBalance ?? 0)

            // Update local
            if mergedBalance != localBalance {
                _pointsBalance = mergedBalance
                keychain.set(mergedBalance, forKey: Self.pointsBalanceKey)
            }

            // Upsert remote
            try await upsertRemotePoints(
                baseURL: baseURL,
                anonKey: anonKey,
                accessToken: accessToken,
                userId: userId,
                balance: mergedBalance
            )
        } catch {
            print("[SubscriptionService] ⚠️ Points sync failed: \(error)")
        }
    }

    /// Fire-and-forget push of current balance to server.
    func pushPointsToServer(authService: AuthServiceProtocol) {
        guard authService.isAuthenticated,
              let userId = authService.currentUserId,
              let accessToken = authService.accessToken else { return }

        let balance = _pointsBalance
        let baseURL = supabaseBaseURL
        let anonKey = supabaseAnonKey

        Task.detached {
            try? await self.upsertRemotePoints(
                baseURL: baseURL,
                anonKey: anonKey,
                accessToken: accessToken,
                userId: userId,
                balance: balance
            )
        }
    }

    private nonisolated func upsertRemotePoints(
        baseURL: String,
        anonKey: String,
        accessToken: String,
        userId: String,
        balance: Int
    ) async throws {
        guard let url = URL(string: "\(baseURL)/rest/v1/user_points") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("resolution=merge-duplicates", forHTTPHeaderField: "Prefer")

        let body: [String: Any] = [
            "user_id": userId,
            "balance": balance,
            "updated_at": ISO8601DateFormatter().string(from: Date())
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (_, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            print("[SubscriptionService] ⚠️ Remote points upsert failed: HTTP \(http.statusCode)")
        }
    }

    // MARK: - Debug

    #if DEBUG
    func debugTogglePremium() {
        isPremium.toggle()
    }

    func debugSetPoints(_ count: Int) {
        _pointsBalance = count
        keychain.set(count, forKey: Self.pointsBalanceKey)
    }

    func debugAddLaunchPoints() {
        addPoints(4)
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
