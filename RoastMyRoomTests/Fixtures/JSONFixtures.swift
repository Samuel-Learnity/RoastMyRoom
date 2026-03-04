import Foundation

enum JSONFixtures {
    static let validScanResult = """
    {
        "room_type": "bedroom",
        "overall_score": 7.5,
        "style": "Scandinavian",
        "sub_scores": {
            "color_harmony": 8.0,
            "proportions": 7.0,
            "lighting": 7.5,
            "cleanliness": 8.5,
            "personality": 6.5
        },
        "tips": [
            {"text": "Add a warm floor lamp", "impact": 0.8},
            {"text": "Choose softer accent colors", "impact": 0.6},
            {"text": "Hide cables behind furniture", "impact": 0.4}
        ],
        "roast": "Your room has the personality of a dentist's waiting room.",
        "verdict": "Not bad",
        "personality": {
            "traits": ["Minimalist at heart", "Secretly chaotic", "Coffee addict"],
            "celebrity_match": "Jake Peralta — organized chaos energy",
            "dating_line": "Your date would think you have a Pinterest board for everything."
        },
        "sub_score_comments": {
            "color_harmony": "The color palette is cohesive and calming.",
            "proportions": "Furniture layout makes sense, mostly.",
            "lighting": "Natural light does the heavy lifting here.",
            "cleanliness": "Impressively tidy for a human.",
            "personality": "Some personal touches would go a long way."
        },
        "mood_board": {
            "color_palette": ["#E8D5B7", "#2C3E50", "#D4A574", "#8B9DC3", "#F5E6CC"],
            "suggestions": [
                "A warm beige rug 160×230",
                "Replace the bulb with a 2700K warm light",
                "Add 2-3 navy blue cushions"
            ]
        }
    }
    """.data(using: .utf8)!

    static let minimalScanResult = """
    {
        "room_type": "living_room",
        "overall_score": 3.2,
        "style": "Student Chaos",
        "sub_scores": {
            "color_harmony": 2.0,
            "proportions": 3.5,
            "lighting": 4.0,
            "cleanliness": 2.5,
            "personality": 4.0
        },
        "tips": [
            {"text": "Clean up first", "impact": 0.9}
        ],
        "roast": "This room screams 'I gave up'.",
        "verdict": "Oof"
    }
    """.data(using: .utf8)!

    static let invalidJSON = """
    { "not": "a scan result" }
    """.data(using: .utf8)!

    static let malformedJSON = """
    { broken json {{
    """.data(using: .utf8)!
}
