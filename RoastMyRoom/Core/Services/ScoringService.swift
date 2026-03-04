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
        #if DEBUG
        print("[ScoringService] Image compressed: \(compressed.count) bytes (\(compressed.count / 1024)KB)")
        #endif

        let data = try await apiClient.post("/score", body: compressed)
        #if DEBUG
        print("[ScoringService] Response received: \(data.count) bytes")
        if let rawJSON = String(data: data, encoding: .utf8) {
            print("[ScoringService] Raw response: \(rawJSON.prefix(500))")
        }
        #endif

        do {
            let result = try JSONDecoder().decode(ScanResult.self, from: data)
            #if DEBUG
            print("[ScoringService] ✅ Decoded successfully: score=\(result.overallScore), style=\(result.style)")
            #endif
            return result
        } catch {
            #if DEBUG
            print("[ScoringService] ⚠️ Decoding failed: \(error)")
            print("[ScoringService] Retrying...")
            #endif
            let retryData = try await apiClient.post("/score", body: compressed)
            #if DEBUG
            if let retryJSON = String(data: retryData, encoding: .utf8) {
                print("[ScoringService] Retry response: \(retryJSON.prefix(500))")
            }
            #endif
            do {
                let result = try JSONDecoder().decode(ScanResult.self, from: retryData)
                #if DEBUG
                print("[ScoringService] ✅ Retry decoded successfully")
                #endif
                return result
            } catch {
                #if DEBUG
                print("[ScoringService] ❌ Retry decoding also failed: \(error)")
                #endif
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
