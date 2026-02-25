import SwiftUI

extension Color {
    static let rsAccent = Color("AccentColor")
    static let rsSuccess = Color.green
    static let rsWarning = Color.orange
    static let rsDanger = Color.red
    static let rsGlass = Color.white.opacity(0.7)

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
