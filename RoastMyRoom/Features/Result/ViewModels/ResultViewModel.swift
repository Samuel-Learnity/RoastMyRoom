import SwiftUI
import Observation

@MainActor
@Observable
final class ResultViewModel {
    let scanResult: ScanResult
    let image: UIImage
    let isPremium: Bool

    var showShareSheet = false
    var shareImage: UIImage?

    init(scanResult: ScanResult, image: UIImage, isPremium: Bool = false) {
        self.scanResult = scanResult
        self.image = image
        self.isPremium = isPremium
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
