import SwiftUI
import SwiftData
import Observation

@MainActor
@Observable
final class HistoryViewModel {
    private(set) var scans: [RoomScan] = []
    private(set) var isLoading = true
    var scanToDelete: RoomScan?
    var showDeleteConfirmation = false

    private let storageService: StorageServiceProtocol
    private let modelContext: ModelContext

    init(storageService: StorageServiceProtocol, modelContext: ModelContext) {
        self.storageService = storageService
        self.modelContext = modelContext
    }

    func loadScans() {
        scans = storageService.fetchAll(in: modelContext)
        isLoading = false
    }

    func confirmDelete(_ scan: RoomScan) {
        scanToDelete = scan
        showDeleteConfirmation = true
    }

    func deleteConfirmed() {
        guard let scan = scanToDelete else { return }
        storageService.delete(scan, in: modelContext)
        scanToDelete = nil
        loadScans()
    }

    // MARK: - Sections

    var thisWeekScans: [RoomScan] {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return scans.filter { $0.createdAt >= weekAgo }
    }

    var olderScans: [RoomScan] {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return scans.filter { $0.createdAt < weekAgo }
    }

    var isEmpty: Bool {
        scans.isEmpty
    }
}
