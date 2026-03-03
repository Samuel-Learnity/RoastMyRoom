import Foundation

nonisolated struct SubScoreComments: Codable, Equatable, Sendable {
    let colorHarmony: String
    let proportions: String
    let lighting: String
    let cleanliness: String
    let personality: String

    enum CodingKeys: String, CodingKey {
        case colorHarmony = "color_harmony"
        case proportions
        case lighting
        case cleanliness
        case personality
    }
}
