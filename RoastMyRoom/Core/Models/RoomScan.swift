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
        isPremiumResult: Bool = false
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
            verdict: result.verdict
        )
    }
}
