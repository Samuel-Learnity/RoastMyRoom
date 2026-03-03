import UIKit

nonisolated final class ShareCardRenderer: Sendable {

    // MARK: - Public API

    func render(
        image: UIImage,
        scanResult: ScanResult,
        isPremium: Bool,
        size: CGSize = CGSize(width: 1080, height: 1920)
    ) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { context in
            let rect = CGRect(origin: .zero, size: size)
            let marginH: CGFloat = 60
            let contentW = rect.width - 2 * marginH

            // Background
            Self.bgBase.setFill()
            context.fill(rect)

            // 1. Hero zone
            var y = drawHeroZone(
                image: image,
                score: scanResult.overallScore,
                verdict: scanResult.verdict,
                style: scanResult.style,
                in: rect,
                context: context
            )

            // 2. Roast banner
            y = drawRoastBanner(roast: scanResult.roast, startY: y + 20, marginH: marginH, contentW: contentW, context: context)

            // 3. Celebrity match
            if let personality = scanResult.personality {
                y = drawCelebritySection(personality: personality, isPremium: isPremium, startY: y + 28, marginH: marginH, contentW: contentW)
            }

            // 4. Traits
            if let personality = scanResult.personality, !personality.traits.isEmpty {
                y = drawTraitsRow(traits: personality.traits, isPremium: isPremium, startY: y + 24, marginH: marginH, contentW: contentW)
            }

            // 5. Sub-scores
            y = drawSubScoresSection(subScores: scanResult.subScores, isPremium: isPremium, startY: y + 28, marginH: marginH, contentW: contentW, context: context)

            // 6. Mood board
            if let moodBoard = scanResult.moodBoard {
                y = drawMoodBoardSection(moodBoard: moodBoard, isPremium: isPremium, startY: y + 28, marginH: marginH, contentW: contentW)
            }

            // 7. Logo watermark (anchored to bottom)
            drawLogoWatermark(in: rect)
        }
    }

    // MARK: - Colors

    private static let bgBase = UIColor(red: 0.04, green: 0.03, blue: 0.09, alpha: 1.0)
    private static let aiPurple = UIColor(red: 0.737, green: 0.510, blue: 0.953, alpha: 1.0)
    private static let aiPink = UIColor(red: 0.961, green: 0.725, blue: 0.918, alpha: 1.0)
    private static let aiLightBlue = UIColor(red: 0.553, green: 0.624, blue: 1.0, alpha: 1.0)
    private static let aiCoral = UIColor(red: 1.0, green: 0.404, blue: 0.471, alpha: 1.0)
    private static let aiPeach = UIColor(red: 1.0, green: 0.729, blue: 0.443, alpha: 1.0)
    private static let aiLavender = UIColor(red: 0.776, green: 0.525, blue: 1.0, alpha: 1.0)
    private static let rsWarning = UIColor(red: 1.0, green: 0.584, blue: 0.0, alpha: 1.0)

    private func scoreColor(for score: Float) -> UIColor {
        switch score {
        case 0..<4:  return UIColor(red: 1.0, green: 0.27, blue: 0.23, alpha: 1.0)
        case 4..<6:  return UIColor(red: 1.0, green: 0.62, blue: 0.04, alpha: 1.0)
        case 6..<8:  return UIColor(red: 0.19, green: 0.82, blue: 0.35, alpha: 1.0)
        default:     return Self.aiPurple
        }
    }

    private func scoreGlowColors(for score: Float) -> [UIColor] {
        switch score {
        case 0..<4:  return [Self.aiCoral, Self.aiPeach, Self.aiPink]
        case 4..<6:  return [Self.aiPeach, Self.aiCoral, Self.aiLavender]
        case 6..<8:  return [Self.aiLightBlue, Self.aiPurple, Self.aiLavender]
        default:     return [Self.aiPurple, Self.aiPink, Self.aiLightBlue]
        }
    }

    // MARK: - Section 1: Hero Zone

    private func drawHeroZone(
        image: UIImage,
        score: Float,
        verdict: String,
        style: String,
        in rect: CGRect,
        context: UIGraphicsImageRendererContext
    ) -> CGFloat {
        let heroHeight: CGFloat = 768

        // Photo (aspect fill, cropped to hero height)
        let imageRatio = image.size.width / image.size.height
        let heroRect = CGRect(x: 0, y: 0, width: rect.width, height: heroHeight)
        let rectRatio = heroRect.width / heroRect.height
        var drawRect: CGRect
        if imageRatio > rectRatio {
            let newWidth = heroHeight * imageRatio
            drawRect = CGRect(x: -(newWidth - rect.width) / 2, y: 0, width: newWidth, height: heroHeight)
        } else {
            let newHeight = rect.width / imageRatio
            drawRect = CGRect(x: 0, y: -(newHeight - heroHeight) / 2, width: rect.width, height: newHeight)
        }

        context.cgContext.saveGState()
        context.cgContext.clip(to: heroRect)
        image.draw(in: drawRect)
        context.cgContext.restoreGState()

        // Gradient fade: clear → bgBase
        let gradColors = [
            UIColor.clear.cgColor,
            Self.bgBase.withAlphaComponent(0.6).cgColor,
            Self.bgBase.cgColor
        ]
        if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: gradColors as CFArray, locations: [0.3, 0.7, 1.0]) {
            context.cgContext.drawLinearGradient(gradient, start: CGPoint(x: rect.midX, y: 0), end: CGPoint(x: rect.midX, y: heroHeight), options: [])
        }

        // Top darkening for status bar readability
        let topColors = [UIColor.black.withAlphaComponent(0.4).cgColor, UIColor.clear.cgColor]
        if let topGrad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: topColors as CFArray, locations: [0.0, 1.0]) {
            context.cgContext.drawLinearGradient(topGrad, start: CGPoint(x: rect.midX, y: 0), end: CGPoint(x: rect.midX, y: 200), options: [])
        }

        // Score ring
        let ringCenter = CGPoint(x: rect.midX, y: 520)
        let ringRadius: CGFloat = 90
        let glowColors = scoreGlowColors(for: score)

        // Glow behind ring
        context.cgContext.saveGState()
        context.cgContext.setShadow(offset: .zero, blur: 30, color: glowColors[0].withAlphaComponent(0.5).cgColor)
        let glowPath = UIBezierPath(arcCenter: ringCenter, radius: ringRadius + 10, startAngle: 0, endAngle: .pi * 2, clockwise: true)
        glowColors[0].withAlphaComponent(0.25).setFill()
        glowPath.fill()
        context.cgContext.restoreGState()

        // Glass disc
        let discPath = UIBezierPath(arcCenter: ringCenter, radius: ringRadius, startAngle: 0, endAngle: .pi * 2, clockwise: true)
        UIColor(white: 0.1, alpha: 0.6).setFill()
        discPath.fill()
        UIColor.white.withAlphaComponent(0.1).setStroke()
        discPath.lineWidth = 1.5
        discPath.stroke()

        // Arc progress
        let progress = CGFloat(min(score / 10.0, 1.0))
        let startAngle: CGFloat = -.pi / 2
        let endAngle = startAngle + (.pi * 2 * progress)
        let arcPath = UIBezierPath(arcCenter: ringCenter, radius: ringRadius - 3, startAngle: startAngle, endAngle: endAngle, clockwise: true)
        context.cgContext.saveGState()
        context.cgContext.setShadow(offset: .zero, blur: 10, color: glowColors[0].withAlphaComponent(0.5).cgColor)
        scoreColor(for: score).setStroke()
        arcPath.lineWidth = 4
        arcPath.lineCapStyle = .round
        arcPath.stroke()
        context.cgContext.restoreGState()

        // Verdict text inside ring
        let verdictFontSize: CGFloat
        switch verdict.count {
        case 0...3: verdictFontSize = 55
        case 4...6: verdictFontSize = 42
        case 7...10: verdictFontSize = 32
        default: verdictFontSize = 26
        }

        let verdictAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: verdictFontSize, weight: .bold).rounded(),
            .foregroundColor: UIColor.white
        ]
        let verdictSize = (verdict as NSString).size(withAttributes: verdictAttrs)
        let verdictPoint = CGPoint(x: ringCenter.x - verdictSize.width / 2, y: ringCenter.y - verdictSize.height / 2 - 8)
        (verdict as NSString).draw(at: verdictPoint, withAttributes: verdictAttrs)

        // "/10" below verdict
        let tenAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 18, weight: .medium).rounded(),
            .foregroundColor: UIColor.white.withAlphaComponent(0.35)
        ]
        let tenSize = ("/10" as NSString).size(withAttributes: tenAttrs)
        let tenPoint = CGPoint(x: ringCenter.x - tenSize.width / 2, y: ringCenter.y + verdictSize.height / 2 - 12)
        ("/10" as NSString).draw(at: tenPoint, withAttributes: tenAttrs)

        // Score pill + Style pill
        let pillY: CGFloat = ringCenter.y + ringRadius + 24

        let scoreText = String(format: "%.1f", score)
        let scorePillFont = UIFont.systemFont(ofSize: 28, weight: .bold).rounded()
        let scoreTenFont = UIFont.systemFont(ofSize: 16, weight: .medium).rounded()
        let scoreSize = (scoreText as NSString).size(withAttributes: [.font: scorePillFont])
        let tenPartSize = ("/10" as NSString).size(withAttributes: [.font: scoreTenFont])
        let scorePillW = scoreSize.width + tenPartSize.width + 8 + 28
        let scorePillH: CGFloat = scoreSize.height + 16

        let stylePillFont = UIFont.systemFont(ofSize: 22, weight: .semibold).rounded()
        let styleSize = (style as NSString).size(withAttributes: [.font: stylePillFont])
        let stylePillW = styleSize.width + 32
        let stylePillH = styleSize.height + 16

        let totalPillsW = scorePillW + 12 + stylePillW
        let pillsStartX = (rect.width - totalPillsW) / 2

        // Score pill
        let scorePillRect = CGRect(x: pillsStartX, y: pillY, width: scorePillW, height: scorePillH)
        drawGlowPill(rect: scorePillRect, glowColor: glowColors[0], context: context)

        let scoreTextPoint = CGPoint(x: scorePillRect.minX + 14, y: scorePillRect.minY + 8)
        (scoreText as NSString).draw(at: scoreTextPoint, withAttributes: [
            .font: scorePillFont,
            .foregroundColor: UIColor.white
        ])
        let tenTextPoint = CGPoint(x: scoreTextPoint.x + scoreSize.width + 4, y: scorePillRect.minY + 12)
        ("/10" as NSString).draw(at: tenTextPoint, withAttributes: [
            .font: scoreTenFont,
            .foregroundColor: UIColor.white.withAlphaComponent(0.4)
        ])

        // Style pill
        let stylePillRect = CGRect(x: scorePillRect.maxX + 12, y: pillY, width: stylePillW, height: stylePillH)
        let stylePath = UIBezierPath(roundedRect: stylePillRect, cornerRadius: stylePillH / 2)
        UIColor.white.withAlphaComponent(0.08).setFill()
        stylePath.fill()
        Self.aiPurple.withAlphaComponent(0.4).setStroke()
        stylePath.lineWidth = 1
        stylePath.stroke()

        let styleTextPoint = CGPoint(x: stylePillRect.minX + 16, y: stylePillRect.minY + 8)
        (style as NSString).draw(at: styleTextPoint, withAttributes: [
            .font: stylePillFont,
            .foregroundColor: UIColor.white
        ])

        return pillY + max(scorePillH, stylePillH)
    }

    // MARK: - Section 2: Roast Banner

    private func drawRoastBanner(roast: String, startY: CGFloat, marginH: CGFloat, contentW: CGFloat, context: UIGraphicsImageRendererContext) -> CGFloat {
        let innerPad: CGFloat = 20
        let roastFont = UIFont.italicSystemFont(ofSize: 26)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 6
        paragraphStyle.lineBreakMode = .byTruncatingTail

        let roastAttrs: [NSAttributedString.Key: Any] = [
            .font: roastFont,
            .foregroundColor: UIColor.white,
            .paragraphStyle: paragraphStyle
        ]
        let textRect = CGRect(x: 0, y: 0, width: contentW - 2 * innerPad, height: .greatestFiniteMagnitude)
        let textHeight = min((roast as NSString).boundingRect(with: textRect.size, options: .usesLineFragmentOrigin, attributes: roastAttrs, context: nil).height, 140)

        let headerHeight: CGFloat = 30
        let bannerHeight = headerHeight + 12 + textHeight + 2 * innerPad
        let bannerRect = CGRect(x: marginH, y: startY, width: contentW, height: bannerHeight)

        // Warm glow
        context.cgContext.saveGState()
        context.cgContext.setShadow(offset: .zero, blur: 16, color: Self.rsWarning.withAlphaComponent(0.35).cgColor)
        let glowPath = UIBezierPath(roundedRect: bannerRect.insetBy(dx: -4, dy: -4), cornerRadius: 24)
        Self.rsWarning.withAlphaComponent(0.08).setFill()
        glowPath.fill()
        context.cgContext.restoreGState()

        // Card background
        drawGlassCard(rect: bannerRect, cornerRadius: 20, strokeColor: Self.rsWarning.withAlphaComponent(0.3))

        // Flame icon + label
        if let flame = sfSymbol("flame.fill", pointSize: 20, weight: .semibold, tintColor: Self.rsWarning) {
            flame.draw(at: CGPoint(x: bannerRect.minX + innerPad, y: bannerRect.minY + innerPad))
        }
        let labelAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 20, weight: .semibold),
            .foregroundColor: Self.rsWarning
        ]
        ("ROAST" as NSString).draw(at: CGPoint(x: bannerRect.minX + innerPad + 28, y: bannerRect.minY + innerPad + 1), withAttributes: labelAttrs)

        // Roast text
        let roastDrawRect = CGRect(
            x: bannerRect.minX + innerPad,
            y: bannerRect.minY + innerPad + headerHeight + 8,
            width: contentW - 2 * innerPad,
            height: textHeight
        )
        (roast as NSString).draw(in: roastDrawRect, withAttributes: roastAttrs)

        return bannerRect.maxY
    }

    // MARK: - Section 3: Celebrity Match

    private func drawCelebritySection(personality: PersonalityAnalysis, isPremium: Bool, startY: CGFloat, marginH: CGFloat, contentW: CGFloat) -> CGFloat {
        var y = drawSectionHeader(icon: "star.fill", title: "CELEBRITY MATCH", y: startY, marginH: marginH, contentW: contentW)
        y += 8

        // Parse name vs quote
        let parts = personality.celebrityMatch.components(separatedBy: " \u{2014} ")
        let name = parts.first ?? personality.celebrityMatch
        let quote = parts.count > 1 ? parts.dropFirst().joined(separator: " \u{2014} ") : nil

        // Name with glow
        let nameFont = UIFont.systemFont(ofSize: 30, weight: .semibold).rounded()
        let nameAttrs: [NSAttributedString.Key: Any] = [
            .font: nameFont,
            .foregroundColor: UIColor.white
        ]
        let nameSize = (name as NSString).size(withAttributes: nameAttrs)
        (name as NSString).draw(at: CGPoint(x: marginH, y: y), withAttributes: nameAttrs)
        y += nameSize.height + 4

        // Quote (premium only)
        if isPremium, let quote, !quote.isEmpty {
            let quoteFont = UIFont.italicSystemFont(ofSize: 24)
            let quoteAttrs: [NSAttributedString.Key: Any] = [
                .font: quoteFont,
                .foregroundColor: UIColor.white.withAlphaComponent(0.7)
            ]
            let quoteRect = CGRect(x: marginH, y: y, width: contentW, height: 60)
            (quote as NSString).draw(in: quoteRect, withAttributes: quoteAttrs)
            y += (quote as NSString).boundingRect(with: quoteRect.size, options: .usesLineFragmentOrigin, attributes: quoteAttrs, context: nil).height
        }

        return y
    }

    // MARK: - Section 4: Traits Row

    private func drawTraitsRow(traits: [String], isPremium: Bool, startY: CGFloat, marginH: CGFloat, contentW: CGFloat) -> CGFloat {
        var y = drawSectionHeader(icon: "brain.head.profile.fill", title: "PERSONALITY", y: startY, marginH: marginH, contentW: contentW)
        y += 10

        let font = UIFont.systemFont(ofSize: 20, weight: .medium).rounded()
        let padH: CGFloat = 16
        let padV: CGFloat = 10
        var x: CGFloat = marginH
        let maxX = marginH + contentW

        for (index, trait) in traits.enumerated() {
            let alpha: CGFloat = (!isPremium && index > 0) ? 0.15 : 1.0
            let textAttrs: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: UIColor.white.withAlphaComponent(alpha)
            ]
            let textSize = (trait as NSString).size(withAttributes: textAttrs)
            let capsuleW = textSize.width + 2 * padH
            let capsuleH = textSize.height + 2 * padV

            // Wrap to next line
            if x + capsuleW > maxX && x > marginH {
                x = marginH
                y += capsuleH + 10
            }

            let capsuleRect = CGRect(x: x, y: y, width: capsuleW, height: capsuleH)
            let path = UIBezierPath(roundedRect: capsuleRect, cornerRadius: capsuleH / 2)
            Self.aiPurple.withAlphaComponent(0.2 * alpha).setFill()
            path.fill()
            Self.aiPurple.withAlphaComponent(0.3 * alpha).setStroke()
            path.lineWidth = 1
            path.stroke()

            let textPoint = CGPoint(x: capsuleRect.minX + padH, y: capsuleRect.minY + padV)
            (trait as NSString).draw(at: textPoint, withAttributes: textAttrs)

            x += capsuleW + 10
        }

        let lastCapsuleH = font.lineHeight + 2 * padV
        return y + lastCapsuleH
    }

    // MARK: - Section 5: Sub-Scores

    private func drawSubScoresSection(subScores: SubScores, isPremium: Bool, startY: CGFloat, marginH: CGFloat, contentW: CGFloat, context: UIGraphicsImageRendererContext) -> CGFloat {
        var y = drawSectionHeader(icon: "chart.dots.scatter", title: "BREAKDOWN", y: startY, marginH: marginH, contentW: contentW)
        y += 8

        if !isPremium {
            // Locked placeholder
            let placeholderRect = CGRect(x: marginH, y: y, width: contentW, height: 180)
            drawGlassCard(rect: placeholderRect, cornerRadius: 20)
            if let lockIcon = sfSymbol("lock.fill", pointSize: 28, weight: .medium, tintColor: .white.withAlphaComponent(0.3)) {
                let iconSize = lockIcon.size
                lockIcon.draw(at: CGPoint(x: placeholderRect.midX - iconSize.width / 2, y: placeholderRect.midY - iconSize.height / 2))
            }
            return placeholderRect.maxY
        }

        let scores: [(String, String, Float)] = [
            ("paintpalette.fill", "Color Harmony", subScores.colorHarmony),
            ("arrow.up.left.and.arrow.down.right", "Proportions", subScores.proportions),
            ("sun.max.fill", "Lighting", subScores.lighting),
            ("sparkles", "Cleanliness", subScores.cleanliness),
            ("heart.fill", "Personality", subScores.personality)
        ]

        for (iconName, label, value) in scores {
            let rowHeight: CGFloat = 40
            let color = scoreColor(for: value)

            // Icon
            if let icon = sfSymbol(iconName, pointSize: 16, weight: .medium, tintColor: color) {
                icon.draw(at: CGPoint(x: marginH, y: y + (rowHeight - icon.size.height) / 2))
            }

            // Label
            let labelAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 20, weight: .medium),
                .foregroundColor: UIColor.white
            ]
            (label as NSString).draw(at: CGPoint(x: marginH + 30, y: y + 8), withAttributes: labelAttrs)

            // Score value
            let valueText = String(format: "%.1f", value)
            let valueAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 20, weight: .bold).rounded(),
                .foregroundColor: color
            ]
            let valueSize = (valueText as NSString).size(withAttributes: valueAttrs)
            (valueText as NSString).draw(at: CGPoint(x: marginH + contentW - valueSize.width, y: y + 8), withAttributes: valueAttrs)

            // Progress bar
            let barY = y + rowHeight - 8
            let barW = contentW - 80
            let barH: CGFloat = 4
            let barX = marginH + 30

            let bgBarPath = UIBezierPath(roundedRect: CGRect(x: barX, y: barY, width: barW, height: barH), cornerRadius: 2)
            color.withAlphaComponent(0.12).setFill()
            bgBarPath.fill()

            let fillW = barW * CGFloat(min(value / 10.0, 1.0))
            let fillPath = UIBezierPath(roundedRect: CGRect(x: barX, y: barY, width: fillW, height: barH), cornerRadius: 2)
            color.withAlphaComponent(0.5).setFill()
            fillPath.fill()

            y += rowHeight + 6
        }

        return y
    }

    // MARK: - Section 6: Mood Board

    private func drawMoodBoardSection(moodBoard: MoodBoard, isPremium: Bool, startY: CGFloat, marginH: CGFloat, contentW: CGFloat) -> CGFloat {
        var y = drawSectionHeader(icon: "swatchpalette.fill", title: "MOOD BOARD", y: startY, marginH: marginH, contentW: contentW)
        y += 10

        // Color palette circles
        let circleSize: CGFloat = 36
        let circleSpacing: CGFloat = 16
        let paletteCount = moodBoard.colorPalette.count
        let totalPaletteW = CGFloat(paletteCount) * circleSize + CGFloat(max(0, paletteCount - 1)) * circleSpacing
        var circleX = (contentW - totalPaletteW) / 2 + marginH
        let paletteAlpha: CGFloat = isPremium ? 1.0 : 0.3

        for hex in moodBoard.colorPalette {
            let color = uiColor(fromHex: hex) ?? .gray
            let circleRect = CGRect(x: circleX, y: y, width: circleSize, height: circleSize)
            let circlePath = UIBezierPath(ovalIn: circleRect)
            color.withAlphaComponent(paletteAlpha).setFill()
            circlePath.fill()
            UIColor.white.withAlphaComponent(0.2 * paletteAlpha).setStroke()
            circlePath.lineWidth = 1
            circlePath.stroke()
            circleX += circleSize + circleSpacing
        }
        y += circleSize + 16

        // Suggestions
        let numFont = UIFont.systemFont(ofSize: 18, weight: .bold).rounded()
        let sugFont = UIFont.systemFont(ofSize: 20, weight: .regular)

        for (index, suggestion) in moodBoard.suggestions.enumerated() {
            let alpha: CGFloat = (!isPremium && index > 0) ? 0.15 : 1.0

            // Number circle
            let numText = "\(index + 1)"
            let numSize = (numText as NSString).size(withAttributes: [.font: numFont])
            let numCircleSize: CGFloat = 28
            let numCirclePath = UIBezierPath(ovalIn: CGRect(x: marginH, y: y, width: numCircleSize, height: numCircleSize))
            Self.aiPurple.withAlphaComponent(0.15 * alpha).setFill()
            numCirclePath.fill()

            let numAttrs: [NSAttributedString.Key: Any] = [
                .font: numFont,
                .foregroundColor: Self.aiPurple.withAlphaComponent(alpha)
            ]
            (numText as NSString).draw(at: CGPoint(x: marginH + (numCircleSize - numSize.width) / 2, y: y + (numCircleSize - numSize.height) / 2), withAttributes: numAttrs)

            // Suggestion text
            let sugAttrs: [NSAttributedString.Key: Any] = [
                .font: sugFont,
                .foregroundColor: UIColor.white.withAlphaComponent(alpha)
            ]
            let sugRect = CGRect(x: marginH + numCircleSize + 12, y: y + 2, width: contentW - numCircleSize - 12, height: 50)
            (suggestion as NSString).draw(in: sugRect, withAttributes: sugAttrs)

            let sugHeight = (suggestion as NSString).boundingRect(with: sugRect.size, options: .usesLineFragmentOrigin, attributes: sugAttrs, context: nil).height
            y += max(numCircleSize, sugHeight) + 10
        }

        return y
    }

    // MARK: - Section 7: Logo Watermark

    private func drawLogoWatermark(in rect: CGRect) {
        let centerX = rect.midX
        let logoSize: CGFloat = 64
        let logoY: CGFloat = rect.height - 180

        // Logo icon
        if let logo = UIImage(named: "LaunchIcon") {
            let logoRect = CGRect(x: centerX - logoSize / 2, y: logoY, width: logoSize, height: logoSize)

            // Circular clip
            let clipPath = UIBezierPath(ovalIn: logoRect)
            UIGraphicsGetCurrentContext()?.saveGState()
            clipPath.addClip()
            logo.draw(in: logoRect, blendMode: .normal, alpha: 0.7)
            UIGraphicsGetCurrentContext()?.restoreGState()
        }

        // App name
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center

        let nameAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 28, weight: .semibold),
            .foregroundColor: UIColor.white.withAlphaComponent(0.5),
            .paragraphStyle: paragraphStyle
        ]
        let nameRect = CGRect(x: 0, y: logoY + logoSize + 12, width: rect.width, height: 36)
        ("RoastMyRoom" as NSString).draw(in: nameRect, withAttributes: nameAttrs)

        // URL
        let urlAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 18),
            .foregroundColor: UIColor.white.withAlphaComponent(0.3),
            .paragraphStyle: paragraphStyle
        ]
        let urlRect = CGRect(x: 0, y: nameRect.maxY + 4, width: rect.width, height: 24)
        ("roastmyroom.app" as NSString).draw(in: urlRect, withAttributes: urlAttrs)
    }

    // MARK: - Helpers

    private func drawSectionHeader(icon: String, title: String, y: CGFloat, marginH: CGFloat, contentW: CGFloat) -> CGFloat {
        let headerColor = UIColor.white.withAlphaComponent(0.5)
        let font = UIFont.systemFont(ofSize: 18, weight: .semibold)

        // Icon
        var iconW: CGFloat = 0
        if let iconImage = sfSymbol(icon, pointSize: 16, weight: .semibold, tintColor: Self.aiPurple) {
            iconImage.draw(at: CGPoint(x: marginH, y: y + 2))
            iconW = iconImage.size.width + 8
        }

        // Title
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: headerColor
        ]
        let titleSize = (title as NSString).size(withAttributes: titleAttrs)
        (title as NSString).draw(at: CGPoint(x: marginH + iconW, y: y), withAttributes: titleAttrs)

        // Separator line
        let lineY = y + titleSize.height / 2
        let lineStartX = marginH + iconW + titleSize.width + 12
        let lineEndX = marginH + contentW
        if lineStartX < lineEndX {
            let linePath = UIBezierPath()
            linePath.move(to: CGPoint(x: lineStartX, y: lineY))
            linePath.addLine(to: CGPoint(x: lineEndX, y: lineY))
            UIColor.white.withAlphaComponent(0.15).setStroke()
            linePath.lineWidth = 1
            linePath.stroke()
        }

        return y + titleSize.height
    }

    private func drawGlassCard(rect: CGRect, cornerRadius: CGFloat, strokeColor: UIColor = .white.withAlphaComponent(0.12)) {
        let path = UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius)
        UIColor(white: 1.0, alpha: 0.08).setFill()
        path.fill()
        strokeColor.setStroke()
        path.lineWidth = 1.5
        path.stroke()
    }

    private func drawGlowPill(rect: CGRect, glowColor: UIColor, context: UIGraphicsImageRendererContext) {
        let cornerRadius = rect.height / 2

        // Glow
        context.cgContext.saveGState()
        context.cgContext.setShadow(offset: .zero, blur: 10, color: glowColor.withAlphaComponent(0.4).cgColor)
        let path = UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius)
        UIColor(white: 1.0, alpha: 0.08).setFill()
        path.fill()
        context.cgContext.restoreGState()

        // Stroke
        glowColor.withAlphaComponent(0.4).setStroke()
        path.lineWidth = 1
        path.stroke()
    }

    private func sfSymbol(_ name: String, pointSize: CGFloat, weight: UIImage.SymbolWeight = .regular, tintColor: UIColor) -> UIImage? {
        let config = UIImage.SymbolConfiguration(pointSize: pointSize, weight: weight)
        return UIImage(systemName: name, withConfiguration: config)?
            .withTintColor(tintColor, renderingMode: .alwaysOriginal)
    }

    private func uiColor(fromHex hex: String) -> UIColor? {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        guard hexSanitized.count == 6 else { return nil }
        var rgbValue: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgbValue)
        return UIColor(
            red: CGFloat((rgbValue >> 16) & 0xFF) / 255.0,
            green: CGFloat((rgbValue >> 8) & 0xFF) / 255.0,
            blue: CGFloat(rgbValue & 0xFF) / 255.0,
            alpha: 1.0
        )
    }
}

// MARK: - UIFont Rounded Helper

private extension UIFont {
    nonisolated func rounded() -> UIFont {
        guard let descriptor = fontDescriptor.withDesign(.rounded) else { return self }
        return UIFont(descriptor: descriptor, size: pointSize)
    }
}
