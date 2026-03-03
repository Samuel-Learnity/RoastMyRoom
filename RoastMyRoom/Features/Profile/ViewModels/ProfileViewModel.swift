import SwiftUI
import SwiftData
import Observation

@MainActor
@Observable
final class ProfileViewModel {
    private(set) var isLoading = true
    private(set) var totalScans: Int = 0
    private(set) var averageScore: Float = 0
    private(set) var dominantStyle: String = "—"
    private(set) var isSigningIn = false
    private(set) var authError: String?
    private let storageService: StorageServiceProtocol
    let subscriptionService: SubscriptionServiceProtocol
    let authService: AuthServiceProtocol
    private let modelContext: ModelContext
    let analyticsService: AnalyticsServiceProtocol

    init(
        storageService: StorageServiceProtocol,
        subscriptionService: SubscriptionServiceProtocol,
        authService: AuthServiceProtocol,
        modelContext: ModelContext,
        analyticsService: AnalyticsServiceProtocol = AnalyticsService()
    ) {
        self.storageService = storageService
        self.subscriptionService = subscriptionService
        self.authService = authService
        self.modelContext = modelContext
        self.analyticsService = analyticsService
    }

    func trackUpgradeClicked() {
        analyticsService.track(.profileUpgradeClicked())
    }

    func trackShareAppClicked() {
        analyticsService.track(.profileShareAppClicked())
    }

    func loadStats() async {
        try? await Task.sleep(for: .milliseconds(80))
        syncAuthState()
        refreshStats()
        isLoading = false
    }

    func refreshStats() {
        let scans = storageService.fetchAll(in: modelContext)
        totalScans = scans.count

        if scans.isEmpty {
            averageScore = 0
            dominantStyle = "—"
        } else {
            let total = scans.reduce(Float(0)) { $0 + $1.overallScore }
            averageScore = total / Float(scans.count)

            // Find dominant style
            var styleCounts: [String: Int] = [:]
            for scan in scans {
                styleCounts[scan.style, default: 0] += 1
            }
            dominantStyle = styleCounts.max(by: { $0.value < $1.value })?.key ?? "—"
        }
    }

    var isPremium: Bool {
        subscriptionService.isPremium
    }

    var planLabel: String {
        isPremium ? String(localized: "profile_plan_premium") : String(localized: "profile_plan_free")
    }

    var planIcon: String {
        isPremium ? "crown.fill" : "lock.open"
    }

    // MARK: - Auth

    private(set) var isAuthenticated: Bool = false
    private(set) var userDisplayName: String = ""

    func syncAuthState() {
        isAuthenticated = authService.isAuthenticated
        userDisplayName = authService.userEmail ?? String(localized: "profile_auth_apple_account")
    }

    private(set) var signUpBonusGranted = false

    var showSignUpBonusTeaser: Bool {
        !subscriptionService.signUpBonusClaimed
    }

    func signInWithApple() async {
        isSigningIn = true
        authError = nil
        signUpBonusGranted = false
        analyticsService.track(.authSignInStarted())

        do {
            try await authService.signInWithApple()
            analyticsService.track(.authSignInSuccess())
            // Grant 4 bonus points on first sign-up
            signUpBonusGranted = subscriptionService.grantSignUpBonusIfNeeded()
            // Sync points after sign-in
            await subscriptionService.syncPointsWithServer(authService: authService)
        } catch {
            authError = error.localizedDescription
            analyticsService.track(.authSignInError(error: error.localizedDescription))
        }

        syncAuthState()
        isSigningIn = false
    }

    func signOut() {
        authService.signOut()
        syncAuthState()
        analyticsService.track(.authSignOut())
    }
}
