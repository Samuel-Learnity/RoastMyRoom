import Foundation

nonisolated enum RoomStyle: String, Codable, CaseIterable, Sendable {
    case minimalist = "Minimalist"
    case scandinavian = "Scandinavian"
    case japandi = "Japandi"
    case midCenturyModern = "Mid-Century Modern"
    case industrial = "Industrial"
    case bohemian = "Bohemian"
    case coastal = "Coastal"
    case artDeco = "Art Deco"
    case maximalist = "Maximalist"
    case contemporary = "Contemporary"
    case farmhouse = "Farmhouse"
    case y2k = "Y2K"
    case cottagecore = "Cottagecore"
    case darkAcademia = "Dark Academia"
    case studentChaos = "Student Chaos"
    case grandmacore = "Grandmacore"
    case cluttercore = "Cluttercore"

    var icon: String {
        switch self {
        case .minimalist: return "cube"
        case .scandinavian: return "snowflake"
        case .japandi: return "leaf"
        case .midCenturyModern: return "chair.lounge"
        case .industrial: return "gear"
        case .bohemian: return "sparkles"
        case .coastal: return "water.waves"
        case .artDeco: return "diamond"
        case .maximalist: return "paintpalette"
        case .contemporary: return "square.grid.2x2"
        case .farmhouse: return "house"
        case .y2k: return "star"
        case .cottagecore: return "leaf.circle"
        case .darkAcademia: return "book.closed"
        case .studentChaos: return "exclamationmark.triangle"
        case .grandmacore: return "heart"
        case .cluttercore: return "tray.full"
        }
    }
}
