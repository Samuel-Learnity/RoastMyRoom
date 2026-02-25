import UIKit

protocol ScoringServiceProtocol: Sendable {
    func scoreRoom(image: UIImage) async throws -> ScanResult
}

final class ScoringService: ScoringServiceProtocol {
    private let apiClient: APIClientProtocol
    private let imageProcessor: ImageProcessorProtocol

    init(apiClient: APIClientProtocol, imageProcessor: ImageProcessorProtocol) {
        self.apiClient = apiClient
        self.imageProcessor = imageProcessor
    }

    func scoreRoom(image: UIImage) async throws -> ScanResult {
        // Resize + compress off main thread
        let processor = imageProcessor
        let compressed = try await Task.detached {
            try processor.prepare(image)
        }.value
        print("[ScoringService] Image compressed: \(compressed.count) bytes (\(compressed.count / 1024)KB)")

        let data = try await apiClient.post("/score", body: compressed)
        print("[ScoringService] Response received: \(data.count) bytes")

        if let rawJSON = String(data: data, encoding: .utf8) {
            print("[ScoringService] Raw response: \(rawJSON.prefix(500))")
        }

        do {
            let result = try JSONDecoder().decode(ScanResult.self, from: data)
            print("[ScoringService] ✅ Decoded successfully: score=\(result.overallScore), style=\(result.style)")
            return result
        } catch {
            print("[ScoringService] ⚠️ Decoding failed: \(error)")
            print("[ScoringService] Retrying...")
            let retryData = try await apiClient.post("/score", body: compressed)
            if let retryJSON = String(data: retryData, encoding: .utf8) {
                print("[ScoringService] Retry response: \(retryJSON.prefix(500))")
            }
            do {
                let result = try JSONDecoder().decode(ScanResult.self, from: retryData)
                print("[ScoringService] ✅ Retry decoded successfully")
                return result
            } catch {
                print("[ScoringService] ❌ Retry decoding also failed: \(error)")
                throw error
            }
        }
    }
}

// MARK: - Mock for development/testing

final class MockScoringService: ScoringServiceProtocol {
    var mockResult: ScanResult = .mock
    var delay: UInt64 = 2_000_000_000 // 2s

    func scoreRoom(image: UIImage) async throws -> ScanResult {
        try await Task.sleep(nanoseconds: delay)
        return mockResult
    }
}
