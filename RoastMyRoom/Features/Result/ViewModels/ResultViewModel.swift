import SwiftUI
import Observation

@MainActor
@Observable
final class ResultViewModel {
    let scanResult: ScanResult
    let image: UIImage
    private(set) var isPremium: Bool
    let animateEntrance: Bool
    let analyticsService: AnalyticsServiceProtocol

    var showShareSheet = false
    var shareImage: UIImage?

    init(scanResult: ScanResult, image: UIImage, isPremium: Bool = false, animateEntrance: Bool = true, analyticsService: AnalyticsServiceProtocol = AnalyticsService()) {
        self.scanResult = scanResult
        self.image = image
        self.isPremium = isPremium
        self.animateEntrance = animateEntrance
        self.analyticsService = analyticsService
    }

    func trackResultViewed() {
        analyticsService.track(.resultViewOpened(
            score: Double(scanResult.overallScore),
            style: scanResult.style,
            isPremium: isPremium
        ))
    }

    /// Unlock full content for this scan using 1 point.
    func unlockWithPoint(subscriptionService: SubscriptionServiceProtocol, scan: RoomScan?) {
        analyticsService.track(.resultUnlockClicked(score: Double(scanResult.overallScore)))
        guard subscriptionService.hasPoints else { return }
        subscriptionService.deductPoint()
        isPremium = true
        scan?.isPremiumResult = true
        analyticsService.track(.resultUnlockSuccess(
            score: Double(scanResult.overallScore),
            pointsRemaining: subscriptionService.pointsBalance
        ))
    }

    func generateShareCard() {
        analyticsService.track(.resultShareClicked(score: Double(scanResult.overallScore)))
        let renderer = ShareCardRenderer()
        let capturedImage = image
        let result = scanResult
        let premium = isPremium
        Task {
            let rendered = await Task.detached {
                renderer.render(
                    image: capturedImage,
                    scanResult: result,
                    isPremium: premium
                )
            }.value
            shareImage = rendered
            showShareSheet = true
        }
    }

    var shareText: String {
        String(
            localized: "share_text \(String(format: "%.1f", scanResult.overallScore))"
        )
    }
}
