import SwiftUI
import Observation

@MainActor
@Observable
final class ResultViewModel {
    let scanResult: ScanResult
    let image: UIImage
    private(set) var isPremium: Bool
    let animateEntrance: Bool

    var showShareSheet = false
    var shareImage: UIImage?

    init(scanResult: ScanResult, image: UIImage, isPremium: Bool = false, animateEntrance: Bool = true) {
        self.scanResult = scanResult
        self.image = image
        self.isPremium = isPremium
        self.animateEntrance = animateEntrance
    }

    /// Unlock full content for this scan using 1 point.
    func unlockWithPoint(subscriptionService: SubscriptionService, scan: RoomScan?) {
        guard subscriptionService.hasPoints else { return }
        subscriptionService.deductPoint()
        isPremium = true
        scan?.isPremiumResult = true
    }

    func generateShareCard() {
        let renderer = ShareCardRenderer()
        let capturedImage = image
        let result = scanResult
        let premium = isPremium
        Task {
            let rendered = await Task.detached {
                renderer.render(
                    image: capturedImage,
                    score: result.overallScore,
                    style: result.style,
                    roast: result.roast,
                    verdict: result.verdict,
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
