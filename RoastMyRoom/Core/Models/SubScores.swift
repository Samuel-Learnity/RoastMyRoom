import Foundation

nonisolated struct SubScores: Codable, Equatable, Sendable {
    let colorHarmony: Float
    let proportions: Float
    let lighting: Float
    let cleanliness: Float
    let personality: Float

    enum CodingKeys: String, CodingKey {
        case colorHarmony = "color_harmony"
        case proportions
        case lighting
        case cleanliness
        case personality
    }
}
