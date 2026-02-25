import SwiftUI
import SwiftData
import Observation

@MainActor
@Observable
final class ProfileViewModel {
    private(set) var totalScans: Int = 0
    private(set) var averageScore: Float = 0
    private(set) var dominantStyle: String = "—"
    @ObservationIgnored var preferredAppearance: String {
        get { UserDefaults.standard.string(forKey: "preferredAppearance") ?? "system" }
        set { UserDefaults.standard.set(newValue, forKey: "preferredAppearance") }
    }

    private let storageService: StorageServiceProtocol
    let subscriptionService: SubscriptionService
    private let modelContext: ModelContext

    init(storageService: StorageServiceProtocol, subscriptionService: SubscriptionService, modelContext: ModelContext) {
        self.storageService = storageService
        self.subscriptionService = subscriptionService
        self.modelContext = modelContext
    }

    func loadStats() {
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
}
