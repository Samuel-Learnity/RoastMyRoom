import Foundation

struct PointsPack: Identifiable, Equatable, Sendable {
    let id: String
    let points: Int
    let isBestValue: Bool

    nonisolated(unsafe) static let all: [PointsPack] = [
        PointsPack(id: "roomscore.points.10", points: 10, isBestValue: false),
        PointsPack(id: "roomscore.points.35", points: 35, isBestValue: false),
        PointsPack(id: "roomscore.points.75", points: 75, isBestValue: true),
        PointsPack(id: "roomscore.points.200", points: 200, isBestValue: false),
    ]

    nonisolated static func pack(for productID: String) -> PointsPack? {
        all.first { $0.id == productID }
    }
}
