import Foundation
import SwiftData
import UIKit
@testable import RoastMyRoom

// MARK: - Mock API Client

final class MockAPIClient: APIClientProtocol, @unchecked Sendable {
    var responseData: Data = Data()
    var shouldThrow: Error?
    private(set) var lastEndpoint: String?
    private(set) var callCount = 0

    func post(_ endpoint: String, body: Data) async throws -> Data {
        callCount += 1
        lastEndpoint = endpoint
        if let error = shouldThrow { throw error }
        return responseData
    }
}

// MARK: - Mock Scoring Service

final class MockScoringService: ScoringServiceProtocol, @unchecked Sendable {
    var mockResult: ScanResult = .mock
    var shouldThrow: Error?
    var delay: UInt64 = 0

    func scoreRoom(image: UIImage) async throws -> ScanResult {
        if delay > 0 { try await Task.sleep(nanoseconds: delay) }
        if let error = shouldThrow { throw error }
        return mockResult
    }
}

// MARK: - Mock Storage Service

final class MockStorageService: StorageServiceProtocol, @unchecked Sendable {
    private(set) var savedScans: [RoomScan] = []
    var stubbedScans: [RoomScan] = []
    private(set) var deleteCount = 0

    func save(_ scan: RoomScan, in context: ModelContext) {
        savedScans.append(scan)
    }

    func fetchAll(in context: ModelContext) -> [RoomScan] {
        stubbedScans
    }

    func delete(_ scan: RoomScan, in context: ModelContext) {
        deleteCount += 1
        stubbedScans.removeAll { $0.id == scan.id }
    }
}

// MARK: - Mock Analytics Service

final class MockAnalyticsService: AnalyticsServiceProtocol, @unchecked Sendable {
    private(set) var trackedEvents: [AnalyticsEvent] = []
    private(set) var userProperties: [(value: String?, name: String)] = []

    func track(_ event: AnalyticsEvent) {
        trackedEvents.append(event)
    }

    func setUserProperty(_ value: String?, forName name: String) {
        userProperties.append((value: value, name: name))
    }
}

// MARK: - Mock Keychain Service

final class MockKeychainService: KeychainServiceProtocol, @unchecked Sendable {
    private var store: [String: String] = [:]

    func set(_ value: String, forKey key: String) {
        store[key] = value
    }

    func get(forKey key: String) -> String? {
        store[key]
    }

    func set(_ value: Int, forKey key: String) {
        store[key] = String(value)
    }

    func getInt(forKey key: String) -> Int? {
        store[key].flatMap { Int($0) }
    }

    func set(_ value: Date, forKey key: String) {
        store[key] = String(value.timeIntervalSince1970)
    }

    func getDate(forKey key: String) -> Date? {
        store[key].flatMap { Double($0) }.map { Date(timeIntervalSince1970: $0) }
    }

    func set(_ value: Bool, forKey key: String) {
        store[key] = value ? "1" : "0"
    }

    func getBool(forKey key: String) -> Bool? {
        store[key].map { $0 == "1" }
    }

    func delete(forKey key: String) {
        store.removeValue(forKey: key)
    }

    /// Test helper: reset all stored data
    func reset() {
        store.removeAll()
    }
}
