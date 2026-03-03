import Foundation

nonisolated struct ScanResult: Codable, Equatable, Sendable {
    let roomType: String
    let overallScore: Float
    let style: String
    let subScores: SubScores
    let tips: [Tip]
    let roast: String
    let verdict: String
    let personality: PersonalityAnalysis?
    let subScoreComments: SubScoreComments?
    let moodBoard: MoodBoard?

    enum CodingKeys: String, CodingKey {
        case roomType = "room_type"
        case overallScore = "overall_score"
        case style
        case subScores = "sub_scores"
        case tips
        case roast
        case verdict
        case personality
        case subScoreComments = "sub_score_comments"
        case moodBoard = "mood_board"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        roomType = try container.decode(String.self, forKey: .roomType)
        overallScore = try container.decode(Float.self, forKey: .overallScore)
        style = try container.decode(String.self, forKey: .style)
        subScores = try container.decode(SubScores.self, forKey: .subScores)
        tips = try container.decode([Tip].self, forKey: .tips)
        roast = try container.decode(String.self, forKey: .roast)
        verdict = try container.decodeIfPresent(String.self, forKey: .verdict) ?? ""
        personality = try container.decodeIfPresent(PersonalityAnalysis.self, forKey: .personality)
        subScoreComments = try container.decodeIfPresent(SubScoreComments.self, forKey: .subScoreComments)
        moodBoard = try container.decodeIfPresent(MoodBoard.self, forKey: .moodBoard)
    }

    init(
        roomType: String,
        overallScore: Float,
        style: String,
        subScores: SubScores,
        tips: [Tip],
        roast: String,
        verdict: String = "",
        personality: PersonalityAnalysis? = nil,
        subScoreComments: SubScoreComments? = nil,
        moodBoard: MoodBoard? = nil
    ) {
        self.roomType = roomType
        self.overallScore = overallScore
        self.style = style
        self.subScores = subScores
        self.tips = tips
        self.roast = roast
        self.verdict = verdict
        self.personality = personality
        self.subScoreComments = subScoreComments
        self.moodBoard = moodBoard
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
            roast: scan.roast,
            verdict: scan.verdict,
            personality: scan.personalityAnalysis,
            subScoreComments: scan.subScoreCommentsModel,
            moodBoard: scan.moodBoardModel
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
        roast: "That one decorative pillow is doing community service for the whole couch.",
        verdict: "Bof bof",
        personality: PersonalityAnalysis(
            traits: ["Chronic overthinker", "IKEA loyalist", "Hopeless romantic"],
            celebrityMatch: "Nick Miller — ce canap\u{00e9} a v\u{00e9}cu des choses",
            datingLine: "Ton date penserait que t'as un bon cr\u{00e9}dit immobilier."
        ),
        subScoreComments: SubScoreComments(
            colorHarmony: "Ces couleurs se battent en duel et personne gagne.",
            proportions: "T'as mis les meubles au hasard ou c'\u{00e9}tait volontaire ?",
            lighting: "L'\u{00e9}clairage dit 'salle d'attente chez le dentiste'.",
            cleanliness: "Pas d\u{00e9}gueulasse, mais ta m\u{00e8}re serait pas fi\u{00e8}re.",
            personality: "Y'a autant de personnalit\u{00e9} qu'un hall d'a\u{00e9}roport."
        ),
        moodBoard: MoodBoard(
            colorPalette: ["#E8D5B7", "#2C3E50", "#D4A574", "#8B9DC3", "#F5E6CC"],
            suggestions: [
                "Un tapis berb\u{00e8}re beige 160\u{00d7}230",
                "Remplacer l'ampoule par une 2700K",
                "Ajouter 2-3 coussins bleu marine"
            ]
        )
    )
}
