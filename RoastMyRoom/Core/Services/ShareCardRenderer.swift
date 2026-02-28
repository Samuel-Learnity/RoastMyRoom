import UIKit

nonisolated final class ShareCardRenderer: Sendable {
    func render(
        image: UIImage,
        score: Float,
        style: String,
        roast: String,
        verdict: String,
        isPremium: Bool,
        size: CGSize = CGSize(width: 1080, height: 1920)
    ) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { context in
            let rect = CGRect(origin: .zero, size: size)

            // 1. Full bleed photo background (aspect fill)
            drawPhotoBackground(image: image, in: rect)

            // 2. Heavy gradient overlay: dark at bottom for text readability
            drawOverlayGradient(in: rect, context: context)

            // 3. Score (large, center-top area)
            drawScore(score, in: rect)

            // 4. "/10" label below score
            let scoreBottomY = drawScoreSubtitle(in: rect)

            // 4b. Verdict label below "/10"
            let verdictBottomY = drawVerdict(verdict, below: scoreBottomY, color: scoreColor(for: score), in: rect)

            // 5. Style badge capsule
            drawStyleBadge(style, below: verdictBottomY, in: rect)

            // 6. Roast quote (centered, lower area)
            drawRoast(roast, in: rect)

            // 7. Branding footer
            drawBranding(in: rect, isPremium: isPremium)

            // 8. Watermark for free users
            if !isPremium {
                drawWatermark(in: rect)
            }
        }
    }

    // MARK: - Score color matching app theme

    private func scoreColor(for score: Float) -> UIColor {
        switch score {
        case 0..<4:  return UIColor(red: 1.0, green: 0.27, blue: 0.23, alpha: 1.0) // #FF453A
        case 4..<6:  return UIColor(red: 1.0, green: 0.62, blue: 0.04, alpha: 1.0) // #FF9F0A
        case 6..<8:  return UIColor(red: 0.19, green: 0.82, blue: 0.35, alpha: 1.0) // #30D158
        default:     return UIColor(red: 0.737, green: 0.510, blue: 0.953, alpha: 1.0) // #BC82F3
        }
    }

    // MARK: - Drawing Helpers

    private func drawPhotoBackground(image: UIImage, in rect: CGRect) {
        let imageRatio = image.size.width / image.size.height
        let rectRatio = rect.width / rect.height
        var drawRect = rect

        if imageRatio > rectRatio {
            let newWidth = rect.height * imageRatio
            drawRect = CGRect(
                x: -(newWidth - rect.width) / 2,
                y: 0,
                width: newWidth,
                height: rect.height
            )
        } else {
            let newHeight = rect.width / imageRatio
            drawRect = CGRect(
                x: 0,
                y: -(newHeight - rect.height) / 2,
                width: rect.width,
                height: newHeight
            )
        }

        image.draw(in: drawRect)
    }

    private func drawOverlayGradient(in rect: CGRect, context: UIGraphicsImageRendererContext) {
        // Top: subtle darkening for score readability
        let topColors = [
            UIColor.black.withAlphaComponent(0.5).cgColor,
            UIColor.clear.cgColor
        ]
        if let topGradient = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: topColors as CFArray,
            locations: [0.0, 0.35]
        ) {
            context.cgContext.drawLinearGradient(
                topGradient,
                start: CGPoint(x: rect.midX, y: 0),
                end: CGPoint(x: rect.midX, y: rect.height * 0.4),
                options: []
            )
        }

        // Bottom: heavy gradient for roast + branding readability
        let bottomColors = [
            UIColor.clear.cgColor,
            UIColor.black.withAlphaComponent(0.55).cgColor,
            UIColor.black.withAlphaComponent(0.85).cgColor
        ]
        if let bottomGradient = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: bottomColors as CFArray,
            locations: [0.0, 0.5, 1.0]
        ) {
            context.cgContext.drawLinearGradient(
                bottomGradient,
                start: CGPoint(x: rect.midX, y: rect.height * 0.45),
                end: CGPoint(x: rect.midX, y: rect.maxY),
                options: []
            )
        }
    }

    private func drawScore(_ score: Float, in rect: CGRect) {
        let scoreText = String(format: "%.1f", score)
        let color = scoreColor(for: score)

        // Drop shadow (double layer for readability on any background)
        let shadowFont = UIFont.systemFont(ofSize: 144, weight: .bold, width: .condensed)
        let shadowAttrs: [NSAttributedString.Key: Any] = [
            .font: shadowFont,
            .foregroundColor: UIColor.black.withAlphaComponent(0.5)
        ]
        let size = (scoreText as NSString).size(withAttributes: shadowAttrs)
        let shadowPoint = CGPoint(
            x: (rect.width - size.width) / 2 + 6,
            y: rect.height * 0.12 + 6
        )
        (scoreText as NSString).draw(at: shadowPoint, withAttributes: shadowAttrs)

        // Main score
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 144, weight: .bold, width: .condensed),
            .foregroundColor: color
        ]
        let point = CGPoint(
            x: (rect.width - size.width) / 2,
            y: rect.height * 0.12
        )
        (scoreText as NSString).draw(at: point, withAttributes: attrs)
    }

    @discardableResult
    private func drawScoreSubtitle(in rect: CGRect) -> CGFloat {
        let subAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 40, weight: .semibold),
            .foregroundColor: UIColor.white.withAlphaComponent(0.7)
        ]
        let scoreFont = UIFont.systemFont(ofSize: 144, weight: .bold, width: .condensed)
        let scoreHeight = ("0" as NSString).size(withAttributes: [.font: scoreFont]).height
        let subSize = ("/10" as NSString).size(withAttributes: subAttrs)
        let y = rect.height * 0.12 + scoreHeight + 4
        let point = CGPoint(x: (rect.width - subSize.width) / 2, y: y)
        ("/10" as NSString).draw(at: point, withAttributes: subAttrs)
        return y + subSize.height
    }

    @discardableResult
    private func drawVerdict(_ verdict: String, below y: CGFloat, color: UIColor, in rect: CGRect) -> CGFloat {
        guard !verdict.isEmpty else { return y }
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 36, weight: .heavy, width: .condensed),
            .foregroundColor: color
        ]
        let size = (verdict.uppercased() as NSString).size(withAttributes: attrs)
        let point = CGPoint(x: (rect.width - size.width) / 2, y: y + 8)
        (verdict.uppercased() as NSString).draw(at: point, withAttributes: attrs)
        return y + 8 + size.height
    }

    private func drawStyleBadge(_ style: String, below scoreBottomY: CGFloat, in rect: CGRect) {
        let textAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 32, weight: .semibold),
            .foregroundColor: UIColor.white
        ]
        let textSize = (style as NSString).size(withAttributes: textAttrs)
        let paddingH: CGFloat = 40
        let paddingV: CGFloat = 20
        let badgeRect = CGRect(
            x: (rect.width - textSize.width - paddingH) / 2,
            y: scoreBottomY + 24,
            width: textSize.width + paddingH,
            height: textSize.height + paddingV
        )

        let path = UIBezierPath(roundedRect: badgeRect, cornerRadius: badgeRect.height / 2)
        UIColor.white.withAlphaComponent(0.2).setFill()
        path.fill()

        // Thin border
        UIColor.white.withAlphaComponent(0.3).setStroke()
        path.lineWidth = 2
        path.stroke()

        let textPoint = CGPoint(
            x: badgeRect.origin.x + paddingH / 2,
            y: badgeRect.origin.y + paddingV / 2
        )
        (style as NSString).draw(at: textPoint, withAttributes: textAttrs)
    }

    private func drawRoast(_ roast: String, in rect: CGRect) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        paragraphStyle.lineBreakMode = .byWordWrapping
        paragraphStyle.lineSpacing = 6

        // Quotation mark decorative
        let quoteAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 72, weight: .bold),
            .foregroundColor: UIColor.white.withAlphaComponent(0.25)
        ]
        let quotePoint = CGPoint(x: 60, y: rect.height * 0.66)
        ("\u{201C}" as NSString).draw(at: quotePoint, withAttributes: quoteAttrs)

        // Roast text
        let textAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.italicSystemFont(ofSize: 28),
            .foregroundColor: UIColor.white,
            .paragraphStyle: paragraphStyle
        ]
        let textRect = CGRect(
            x: 72,
            y: rect.height * 0.70,
            width: rect.width - 144,
            height: 250
        )
        (roast as NSString).draw(in: textRect, withAttributes: textAttrs)
    }

    private func drawBranding(in rect: CGRect, isPremium: Bool) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center

        let brandAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 28, weight: .semibold),
            .foregroundColor: UIColor.white.withAlphaComponent(0.6),
            .paragraphStyle: paragraphStyle
        ]
        let brandRect = CGRect(x: 0, y: rect.height - 110, width: rect.width, height: 40)
        ("RoastMyRoom" as NSString).draw(in: brandRect, withAttributes: brandAttrs)

        let urlAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 20),
            .foregroundColor: UIColor.white.withAlphaComponent(0.4),
            .paragraphStyle: paragraphStyle
        ]
        let urlRect = CGRect(x: 0, y: rect.height - 70, width: rect.width, height: 30)
        ("roastmyroom.app" as NSString).draw(in: urlRect, withAttributes: urlAttrs)
    }

    private func drawWatermark(in rect: CGRect) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center

        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 42, weight: .bold),
            .foregroundColor: UIColor.white.withAlphaComponent(0.12),
            .paragraphStyle: paragraphStyle
        ]
        let watermarkRect = CGRect(
            x: 0,
            y: rect.height * 0.48 - 25,
            width: rect.width,
            height: 50
        )
        ("roastmyroom.app" as NSString).draw(in: watermarkRect, withAttributes: attrs)
    }
}
