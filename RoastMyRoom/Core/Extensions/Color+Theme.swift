import SwiftUI

extension Color {
    static let rsAccent = Color("AccentColor")
    static let rsSuccess = Color.green
    static let rsWarning = Color.orange
    static let rsDanger = Color.red
    static let rsGlass = Color.white.opacity(0.7)

    // MARK: - Background Base

    static let rsBgBase = Color("BackgroundColor")

    // MARK: - Glass Card

    static let rsCardStroke = Color.white.opacity(0.12)

    // MARK: - Apple Intelligence Neon Palette

    static let aiPurple = Color(red: 0.737, green: 0.510, blue: 0.953)     // #BC82F3
    static let aiPink = Color(red: 0.961, green: 0.725, blue: 0.918)       // #F5B9EA
    static let aiLightBlue = Color(red: 0.553, green: 0.624, blue: 1.0)    // #8D9FFF
    static let aiDeepPurple = Color(red: 0.667, green: 0.431, blue: 0.933) // #AA6EEE
    static let aiCoral = Color(red: 1.0, green: 0.404, blue: 0.471)        // #FF6778
    static let aiPeach = Color(red: 1.0, green: 0.729, blue: 0.443)        // #FFBA71
    static let aiLavender = Color(red: 0.776, green: 0.525, blue: 1.0)     // #C686FF

    static let aiNeonPalette: [Color] = [
        .aiPurple, .aiPink, .aiLightBlue, .aiDeepPurple,
        .aiCoral, .aiPeach, .aiLavender, .aiPurple
    ]

    // MARK: - Hex Init

    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if hexSanitized.hasPrefix("#") { hexSanitized.removeFirst() }
        guard hexSanitized.count == 6,
              let rgb = UInt64(hexSanitized, radix: 16) else { return nil }
        self.init(
            red: Double((rgb >> 16) & 0xFF) / 255,
            green: Double((rgb >> 8) & 0xFF) / 255,
            blue: Double(rgb & 0xFF) / 255
        )
    }

    // MARK: - Score

    static func scoreColor(for score: Float) -> Color {
        switch score {
        case 0..<4:
            return .rsDanger
        case 4..<6:
            return .rsWarning
        case 6..<8:
            return .rsSuccess
        default:
            return .rsAccent
        }
    }
}
