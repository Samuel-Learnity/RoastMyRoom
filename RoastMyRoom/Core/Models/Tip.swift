import Foundation

nonisolated struct Tip: Codable, Equatable, Identifiable, Sendable {
    var id: String { text }

    let text: String
    let impact: Float

    enum CodingKeys: String, CodingKey {
        case text
        case impact
    }
}
