import Foundation

nonisolated struct ScanResult: Codable, Equatable, Sendable {
    let roomType: String
    let overallScore: Float
    let style: String
    let subScores: SubScores
    let tips: [Tip]
    let roast: String

    enum CodingKeys: String, CodingKey {
        case roomType = "room_type"
        case overallScore = "overall_score"
        case style
        case subScores = "sub_scores"
        case tips
        case roast
    }
}

extension ScanResult {
    /// Reconstruct from a persisted RoomScan (for history → result navigation)
    init(from scan: RoomScan) {
        self.init(
            roomType: scan.roomType,
            overallScore: scan.overallScore,
            style: scan.style,
            subScores: scan.subScores ?? SubScores(
                colorHarmony: 0, proportions: 0, lighting: 0, cleanliness: 0, personality: 0
            ),
            tips: scan.tips,
            roast: scan.roast
        )
    }

    static let mock = ScanResult(
        roomType: "bedroom",
        overallScore: 4.9,
        style: "Student Chaos",
        subScores: SubScores(
            colorHarmony: 5.5,
            proportions: 5.0,
            lighting: 6.0,
            cleanliness: 6.5,
            personality: 5.5
        ),
        tips: [
            Tip(text: "Replace the harsh overhead light with a warm floor lamp", impact: 0.8),
            Tip(text: "Pick a two-color palette and ditch the clashing throw pillows", impact: 0.6),
            Tip(text: "Hide cables with an adhesive raceway behind the desk", impact: 0.4)
        ],
        roast: "That one decorative pillow is doing community service for the whole couch."
    )
}
