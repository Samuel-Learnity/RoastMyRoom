import Testing
import Foundation
@testable import RoastMyRoom

@Suite("ScanResult JSON Decoding")
struct ScanResultTests {

    @Test("Decodes valid JSON with all fields")
    func decodesFullJSON() throws {
        let result = try JSONDecoder().decode(ScanResult.self, from: JSONFixtures.validScanResult)

        #expect(result.roomType == "bedroom")
        #expect(result.overallScore == 7.5)
        #expect(result.style == "Scandinavian")
        #expect(result.verdict == "Not bad")
        #expect(result.roast.contains("dentist"))
        #expect(result.tips.count == 3)
    }

    @Test("Decodes sub-scores correctly")
    func decodesSubScores() throws {
        let result = try JSONDecoder().decode(ScanResult.self, from: JSONFixtures.validScanResult)

        #expect(result.subScores.colorHarmony == 8.0)
        #expect(result.subScores.proportions == 7.0)
        #expect(result.subScores.lighting == 7.5)
        #expect(result.subScores.cleanliness == 8.5)
        #expect(result.subScores.personality == 6.5)
    }

    @Test("Decodes tips with impact values")
    func decodesTips() throws {
        let result = try JSONDecoder().decode(ScanResult.self, from: JSONFixtures.validScanResult)

        #expect(result.tips[0].impact == 0.8)
        #expect(result.tips[1].impact == 0.6)
        #expect(result.tips[2].impact == 0.4)
        #expect(result.tips[0].text.contains("warm floor lamp"))
    }

    @Test("Decodes personality analysis")
    func decodesPersonality() throws {
        let result = try JSONDecoder().decode(ScanResult.self, from: JSONFixtures.validScanResult)

        #expect(result.personality != nil)
        #expect(result.personality?.traits.count == 3)
        #expect(result.personality?.celebrityMatch.contains("Jake Peralta") == true)
        #expect(result.personality?.datingLine.isEmpty == false)
    }

    @Test("Decodes sub-score comments")
    func decodesSubScoreComments() throws {
        let result = try JSONDecoder().decode(ScanResult.self, from: JSONFixtures.validScanResult)

        #expect(result.subScoreComments != nil)
        #expect(result.subScoreComments?.colorHarmony.isEmpty == false)
        #expect(result.subScoreComments?.lighting.contains("Natural light") == true)
    }

    @Test("Decodes mood board")
    func decodesMoodBoard() throws {
        let result = try JSONDecoder().decode(ScanResult.self, from: JSONFixtures.validScanResult)

        #expect(result.moodBoard != nil)
        #expect(result.moodBoard?.colorPalette.count == 5)
        #expect(result.moodBoard?.suggestions.count == 3)
    }

    @Test("Decodes minimal JSON without optional fields")
    func decodesMinimalJSON() throws {
        let result = try JSONDecoder().decode(ScanResult.self, from: JSONFixtures.minimalScanResult)

        #expect(result.roomType == "living_room")
        #expect(result.overallScore == 3.2)
        #expect(result.style == "Student Chaos")
        #expect(result.verdict == "Oof")
        #expect(result.tips.count == 1)
        #expect(result.personality == nil)
        #expect(result.subScoreComments == nil)
        #expect(result.moodBoard == nil)
    }

    @Test("Score is within valid range 0-10")
    func scoreInRange() throws {
        let result = try JSONDecoder().decode(ScanResult.self, from: JSONFixtures.validScanResult)
        #expect(result.overallScore >= 0 && result.overallScore <= 10)
    }

    @Test("Rejects invalid JSON structure")
    func rejectsInvalidJSON() {
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(ScanResult.self, from: JSONFixtures.invalidJSON)
        }
    }

    @Test("Rejects malformed JSON")
    func rejectsMalformedJSON() {
        #expect(throws: (any Error).self) {
            try JSONDecoder().decode(ScanResult.self, from: JSONFixtures.malformedJSON)
        }
    }

    @Test("ScanResult round-trips through encode/decode")
    func roundTrip() throws {
        let original = ScanResult.mock
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ScanResult.self, from: data)

        #expect(decoded.overallScore == original.overallScore)
        #expect(decoded.style == original.style)
        #expect(decoded.tips.count == original.tips.count)
        #expect(decoded.roast == original.roast)
    }
}
