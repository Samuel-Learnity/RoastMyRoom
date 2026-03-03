import Foundation
import SwiftData

@Model
final class RoomScan {
    var id: UUID
    @Attribute(.externalStorage) var imageData: Data
    var roomType: String
    var overallScore: Float
    var style: String
    var subScoresData: Data
    var tipsData: Data
    var roast: String
    var verdict: String = ""
    var createdAt: Date
    var isPremiumResult: Bool
    var personalityData: Data?
    var subScoreCommentsData: Data?
    var moodBoardData: Data?

    init(
        id: UUID = UUID(),
        imageData: Data,
        roomType: String,
        overallScore: Float,
        style: String,
        subScoresData: Data,
        tipsData: Data,
        roast: String,
        verdict: String = "",
        createdAt: Date = Date(),
        isPremiumResult: Bool = false,
        personalityData: Data? = nil,
        subScoreCommentsData: Data? = nil,
        moodBoardData: Data? = nil
    ) {
        self.id = id
        self.imageData = imageData
        self.roomType = roomType
        self.overallScore = overallScore
        self.style = style
        self.subScoresData = subScoresData
        self.tipsData = tipsData
        self.roast = roast
        self.verdict = verdict
        self.createdAt = createdAt
        self.isPremiumResult = isPremiumResult
        self.personalityData = personalityData
        self.subScoreCommentsData = subScoreCommentsData
        self.moodBoardData = moodBoardData
    }

    var subScores: SubScores? {
        decodeSubScores(from: subScoresData)
    }

    var tips: [Tip] {
        decodeTips(from: tipsData)
    }

    var roomStyle: RoomStyle? {
        RoomStyle(rawValue: style)
    }

    var personalityAnalysis: PersonalityAnalysis? {
        personalityData.flatMap { decodeModel(PersonalityAnalysis.self, from: $0) }
    }

    var subScoreCommentsModel: SubScoreComments? {
        subScoreCommentsData.flatMap { decodeModel(SubScoreComments.self, from: $0) }
    }

    var moodBoardModel: MoodBoard? {
        moodBoardData.flatMap { decodeModel(MoodBoard.self, from: $0) }
    }
}

// Decoding helpers — nonisolated to avoid Swift 6 actor isolation issues
nonisolated private func decodeSubScores(from data: Data) -> SubScores? {
    try? JSONDecoder().decode(SubScores.self, from: data)
}

nonisolated private func decodeTips(from data: Data) -> [Tip] {
    (try? JSONDecoder().decode([Tip].self, from: data)) ?? []
}

nonisolated private func encodeSubScores(_ subScores: SubScores) -> Data {
    (try? JSONEncoder().encode(subScores)) ?? Data()
}

nonisolated private func encodeTips(_ tips: [Tip]) -> Data {
    (try? JSONEncoder().encode(tips)) ?? Data()
}

nonisolated private func decodeModel<T: Decodable>(_ type: T.Type, from data: Data) -> T? {
    try? JSONDecoder().decode(type, from: data)
}

nonisolated private func encodeModel<T: Encodable>(_ value: T) -> Data? {
    try? JSONEncoder().encode(value)
}

extension RoomScan {
    convenience init(from result: ScanResult, imageData: Data) {
        let subScoresData = encodeSubScores(result.subScores)
        let tipsData = encodeTips(result.tips)

        self.init(
            imageData: imageData,
            roomType: result.roomType,
            overallScore: result.overallScore,
            style: result.style,
            subScoresData: subScoresData,
            tipsData: tipsData,
            roast: result.roast,
            verdict: result.verdict,
            personalityData: result.personality.flatMap { encodeModel($0) },
            subScoreCommentsData: result.subScoreComments.flatMap { encodeModel($0) },
            moodBoardData: result.moodBoard.flatMap { encodeModel($0) }
        )
    }
}
