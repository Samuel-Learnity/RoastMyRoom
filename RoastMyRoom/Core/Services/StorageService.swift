import Foundation
import SwiftData

protocol StorageServiceProtocol: Sendable {
    func save(_ scan: RoomScan, in context: ModelContext)
    func fetchAll(in context: ModelContext) -> [RoomScan]
    func delete(_ scan: RoomScan, in context: ModelContext)
}

final class StorageService: StorageServiceProtocol {
    func save(_ scan: RoomScan, in context: ModelContext) {
        context.insert(scan)
        try? context.save()
    }

    func fetchAll(in context: ModelContext) -> [RoomScan] {
        let descriptor = FetchDescriptor<RoomScan>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    func delete(_ scan: RoomScan, in context: ModelContext) {
        context.delete(scan)
        try? context.save()
    }
}
