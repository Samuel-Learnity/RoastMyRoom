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
    private let analyticsService: AnalyticsServiceProtocol

    init(storageService: StorageServiceProtocol, modelContext: ModelContext, analyticsService: AnalyticsServiceProtocol = AnalyticsService()) {
        self.storageService = storageService
        self.modelContext = modelContext
        self.analyticsService = analyticsService
    }

    func loadScans() async {
        try? await Task.sleep(for: .milliseconds(80))
        refreshScans()
        isLoading = false
    }

    func confirmDelete(_ scan: RoomScan) {
        scanToDelete = scan
        showDeleteConfirmation = true
    }

    func deleteConfirmed() {
        guard let scan = scanToDelete else { return }
        analyticsService.track(.historyDeleteConfirmed(score: Double(scan.overallScore)))
        storageService.delete(scan, in: modelContext)
        scanToDelete = nil
        refreshScans()
    }

    func trackCardTapped(_ scan: RoomScan) {
        analyticsService.track(.historyCardTapped(score: Double(scan.overallScore), style: scan.style))
    }

    func refreshScans() {
        scans = storageService.fetchAll(in: modelContext)
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
