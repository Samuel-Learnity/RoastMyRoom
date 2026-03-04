import Testing
import Foundation
@testable import RoastMyRoom

@Suite("SubScores")
struct SubScoresTests {

    @Test("Decodes from snake_case JSON")
    func decodesSnakeCase() throws {
        let json = """
        {
            "color_harmony": 7.5,
            "proportions": 6.0,
            "lighting": 8.0,
            "cleanliness": 9.0,
            "personality": 5.5
        }
        """.data(using: .utf8)!

        let scores = try JSONDecoder().decode(SubScores.self, from: json)

        #expect(scores.colorHarmony == 7.5)
        #expect(scores.proportions == 6.0)
        #expect(scores.lighting == 8.0)
        #expect(scores.cleanliness == 9.0)
        #expect(scores.personality == 5.5)
    }

    @Test("Equatable works correctly")
    func equatable() {
        let a = SubScores(colorHarmony: 5, proportions: 5, lighting: 5, cleanliness: 5, personality: 5)
        let b = SubScores(colorHarmony: 5, proportions: 5, lighting: 5, cleanliness: 5, personality: 5)
        let c = SubScores(colorHarmony: 6, proportions: 5, lighting: 5, cleanliness: 5, personality: 5)

        #expect(a == b)
        #expect(a != c)
    }

    @Test("Round-trips through encode/decode")
    func roundTrip() throws {
        let original = SubScores(colorHarmony: 8.5, proportions: 7.0, lighting: 6.5, cleanliness: 9.0, personality: 4.0)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(SubScores.self, from: data)

        #expect(decoded == original)
    }
}
