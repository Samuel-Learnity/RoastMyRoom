import UIKit

nonisolated final class ShareCardRenderer: Sendable {
    func render(
        image: UIImage,
        score: Float,
        style: String,
        roast: String,
        isPremium: Bool,
        size: CGSize = CGSize(width: 1080, height: 1920)
    ) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { context in
            let rect = CGRect(origin: .zero, size: size)

            // Background: photo aspect fill with blur
            drawBackground(image: image, in: rect, context: context)

            // Gradient overlay
            drawGradient(in: rect, context: context)

            // Score
            drawScore(score, in: rect, context: context)

            // Style badge
            drawStyleBadge(style, in: rect, context: context)

            // Roast
            drawRoast(roast, in: rect, context: context)

            // Branding
            drawBranding(in: rect, isPremium: isPremium, context: context)
        }
    }

    // MARK: - Drawing Helpers

    private func drawBackground(image: UIImage, in rect: CGRect, context: UIGraphicsImageRendererContext) {
        // Aspect fill
        let imageRatio = image.size.width / image.size.height
        let rectRatio = rect.width / rect.height
        var drawRect = rect

        if imageRatio > rectRatio {
            let newWidth = rect.height * imageRatio
            drawRect = CGRect(x: -(newWidth - rect.width) / 2, y: 0, width: newWidth, height: rect.height)
        } else {
            let newHeight = rect.width / imageRatio
            drawRect = CGRect(x: 0, y: -(newHeight - rect.height) / 2, width: rect.width, height: newHeight)
        }

        image.draw(in: drawRect)

        // Slight blur effect via overlay
        UIColor.black.withAlphaComponent(0.3).setFill()
        context.fill(rect)
    }

    private func drawGradient(in rect: CGRect, context: UIGraphicsImageRendererContext) {
        let colors = [UIColor.clear.cgColor, UIColor.black.withAlphaComponent(0.6).cgColor]
        let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: [0.4, 1.0])!

        context.cgContext.drawLinearGradient(
            gradient,
            start: CGPoint(x: rect.midX, y: 0),
            end: CGPoint(x: rect.midX, y: rect.maxY),
            options: []
        )
    }

    private func drawScore(_ score: Float, in rect: CGRect, context: UIGraphicsImageRendererContext) {
        let scoreText = String(format: "%.1f", score)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 96, weight: .bold),
            .foregroundColor: UIColor.white
        ]
        let size = (scoreText as NSString).size(withAttributes: attrs)
        let point = CGPoint(x: (rect.width - size.width) / 2, y: rect.height * 0.25)
        (scoreText as NSString).draw(at: point, withAttributes: attrs)

        // /10 subtitle
        let subAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 32, weight: .semibold),
            .foregroundColor: UIColor.white.withAlphaComponent(0.7)
        ]
        let subSize = ("/10" as NSString).size(withAttributes: subAttrs)
        let subPoint = CGPoint(x: (rect.width - subSize.width) / 2, y: point.y + size.height + 4)
        ("/10" as NSString).draw(at: subPoint, withAttributes: subAttrs)
    }

    private func drawStyleBadge(_ style: String, in rect: CGRect, context: UIGraphicsImageRendererContext) {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 28, weight: .semibold),
            .foregroundColor: UIColor.white
        ]
        let size = (style as NSString).size(withAttributes: attrs)
        let badgeRect = CGRect(
            x: (rect.width - size.width - 32) / 2,
            y: rect.height * 0.45,
            width: size.width + 32,
            height: size.height + 16
        )

        let path = UIBezierPath(roundedRect: badgeRect, cornerRadius: badgeRect.height / 2)
        UIColor.white.withAlphaComponent(0.2).setFill()
        path.fill()

        let textPoint = CGPoint(x: badgeRect.origin.x + 16, y: badgeRect.origin.y + 8)
        (style as NSString).draw(at: textPoint, withAttributes: attrs)
    }

    private func drawRoast(_ roast: String, in rect: CGRect, context: UIGraphicsImageRendererContext) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        paragraphStyle.lineBreakMode = .byWordWrapping

        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.italicSystemFont(ofSize: 24),
            .foregroundColor: UIColor.white,
            .paragraphStyle: paragraphStyle
        ]

        let textRect = CGRect(x: 60, y: rect.height * 0.7, width: rect.width - 120, height: 200)
        (roast as NSString).draw(in: textRect, withAttributes: attrs)
    }

    private func drawBranding(in rect: CGRect, isPremium: Bool, context: UIGraphicsImageRendererContext) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center

        let brandAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 20, weight: .medium),
            .foregroundColor: UIColor.white.withAlphaComponent(0.6),
            .paragraphStyle: paragraphStyle
        ]
        let brandRect = CGRect(x: 0, y: rect.height - 80, width: rect.width, height: 30)
        ("RoomScore" as NSString).draw(in: brandRect, withAttributes: brandAttrs)

        let urlAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16),
            .foregroundColor: UIColor.white.withAlphaComponent(0.4),
            .paragraphStyle: paragraphStyle
        ]
        let urlRect = CGRect(x: 0, y: rect.height - 50, width: rect.width, height: 30)
        ("roomscore.app" as NSString).draw(in: urlRect, withAttributes: urlAttrs)

        // Watermark for free users
        if !isPremium {
            let watermarkAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 36, weight: .bold),
                .foregroundColor: UIColor.white.withAlphaComponent(0.15),
                .paragraphStyle: paragraphStyle
            ]
            let watermarkRect = CGRect(x: 0, y: rect.midY - 20, width: rect.width, height: 50)
            ("roomscore.app" as NSString).draw(in: watermarkRect, withAttributes: watermarkAttrs)
        }
    }
}
