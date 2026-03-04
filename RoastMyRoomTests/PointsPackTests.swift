import Testing
@testable import RoastMyRoom

@Suite("PointsPack")
struct PointsPackTests {

    @Test("All packs are defined")
    func allPacksDefined() {
        #expect(PointsPack.all.count == 4)
    }

    @Test("Pack IDs match StoreKit product IDs")
    func packIDsMatchProducts() {
        let ids = PointsPack.all.map(\.id)
        #expect(ids.contains("roomscore.points.10"))
        #expect(ids.contains("roomscore.points.35"))
        #expect(ids.contains("roomscore.points.75"))
        #expect(ids.contains("roomscore.points.200"))
    }

    @Test("Pack points are correct")
    func packPointsCorrect() {
        #expect(PointsPack.pack(for: "roomscore.points.10")?.points == 10)
        #expect(PointsPack.pack(for: "roomscore.points.35")?.points == 35)
        #expect(PointsPack.pack(for: "roomscore.points.75")?.points == 75)
        #expect(PointsPack.pack(for: "roomscore.points.200")?.points == 200)
    }

    @Test("Best value flag is on 75 points pack")
    func bestValuePack() {
        let bestValue = PointsPack.all.filter(\.isBestValue)
        #expect(bestValue.count == 1)
        #expect(bestValue.first?.id == "roomscore.points.75")
    }

    @Test("Unknown product ID returns nil")
    func unknownProductReturnsNil() {
        #expect(PointsPack.pack(for: "unknown.product") == nil)
    }
}
