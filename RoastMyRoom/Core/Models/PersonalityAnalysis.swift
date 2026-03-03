import Foundation

nonisolated struct PersonalityAnalysis: Codable, Equatable, Sendable {
    let traits: [String]
    let celebrityMatch: String
    let datingLine: String

    enum CodingKeys: String, CodingKey {
        case traits
        case celebrityMatch = "celebrity_match"
        case datingLine = "dating_line"
    }
}
