import Foundation

nonisolated struct MoodBoard: Codable, Equatable, Sendable {
    let colorPalette: [String]
    let suggestions: [String]

    enum CodingKeys: String, CodingKey {
        case colorPalette = "color_palette"
        case suggestions
    }
}
