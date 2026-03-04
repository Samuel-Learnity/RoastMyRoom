import Testing
import Foundation
@testable import RoastMyRoom

@Suite("SubscriptionService — Points Logic")
struct SubscriptionServicePointsTests {

    @Test("Initial launch grants 4 free points")
    @MainActor
    func initialPointsGrant() {
        let keychain = MockKeychainService()
        let service = SubscriptionService(keychainService: keychain)

        #expect(service.pointsBalance == 4)
    }

    @Test("Second launch does not re-grant points")
    @MainActor
    func noDoubleGrant() {
        let keychain = MockKeychainService()
        keychain.set(true, forKey: "pointsBalanceInitialized")
        keychain.set(4, forKey: "pointsBalance")

        let service = SubscriptionService(keychainService: keychain)

        #expect(service.pointsBalance == 4)
    }

    @Test("Deduct point decrements balance")
    @MainActor
    func deductPoint() {
        let keychain = MockKeychainService()
        let service = SubscriptionService(keychainService: keychain)

        let initial = service.pointsBalance
        service.deductPoint()

        #expect(service.pointsBalance == initial - 1)
    }

    @Test("Deduct point at zero stays at zero")
    @MainActor
    func deductAtZero() {
        let keychain = MockKeychainService()
        keychain.set(true, forKey: "pointsBalanceInitialized")
        keychain.set(0, forKey: "pointsBalance")

        let service = SubscriptionService(keychainService: keychain)
        service.deductPoint()

        #expect(service.pointsBalance == 0)
    }

    @Test("hasPoints is true when balance > 0")
    @MainActor
    func hasPointsTrue() {
        let keychain = MockKeychainService()
        let service = SubscriptionService(keychainService: keychain)

        #expect(service.hasPoints == true)
    }

    @Test("hasPoints is false when balance is 0")
    @MainActor
    func hasPointsFalse() {
        let keychain = MockKeychainService()
        keychain.set(true, forKey: "pointsBalanceInitialized")
        keychain.set(0, forKey: "pointsBalance")

        let service = SubscriptionService(keychainService: keychain)

        #expect(service.hasPoints == false)
    }

    @Test("Sign-up bonus grants 4 points once")
    @MainActor
    func signUpBonus() {
        let keychain = MockKeychainService()
        let service = SubscriptionService(keychainService: keychain)
        let before = service.pointsBalance

        let granted = service.grantSignUpBonusIfNeeded()

        #expect(granted == true)
        #expect(service.pointsBalance == before + 4)
    }

    @Test("Sign-up bonus is not granted twice")
    @MainActor
    func signUpBonusOnce() {
        let keychain = MockKeychainService()
        let service = SubscriptionService(keychainService: keychain)

        service.grantSignUpBonusIfNeeded()
        let balanceAfterFirst = service.pointsBalance

        let grantedAgain = service.grantSignUpBonusIfNeeded()

        #expect(grantedAgain == false)
        #expect(service.pointsBalance == balanceAfterFirst)
    }

    @Test("Free users get 2 daily scans")
    @MainActor
    func freeDailyLimit() {
        let keychain = MockKeychainService()
        keychain.set(true, forKey: "pointsBalanceInitialized")
        keychain.set(0, forKey: "pointsBalance")

        let service = SubscriptionService(keychainService: keychain)
        // In DEBUG, isPremium defaults to true — toggle off to test free tier
        service.debugTogglePremium()

        #expect(service.remainingScansToday == 2)
        #expect(service.canScan == true)
    }

    @Test("Recording scans decrements remaining count")
    @MainActor
    func recordScanDecrement() {
        let keychain = MockKeychainService()
        let service = SubscriptionService(keychainService: keychain)
        // In DEBUG, isPremium defaults to true — toggle off to test free tier
        service.debugTogglePremium()

        service.recordScan()
        #expect(service.remainingScansToday == 1)

        service.recordScan()
        #expect(service.remainingScansToday == 0)
    }

    @Test("recordScanWithSource returns correct payment source")
    @MainActor
    func scanPaymentSource() {
        let keychain = MockKeychainService()
        let service = SubscriptionService(keychainService: keychain)

        // First 2 scans should be free
        let source1 = service.recordScanWithSource()
        #if DEBUG
        // In DEBUG, isPremium defaults to true
        #expect(source1 == .premium)
        #else
        #expect(source1 == .free)
        #endif
    }
}
