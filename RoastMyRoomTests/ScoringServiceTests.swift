import Testing
import Foundation
import UIKit
@testable import RoastMyRoom

@Suite("ScoringService")
struct ScoringServiceTests {

    @Test("Decodes valid API response into ScanResult")
    func decodesValidResponse() async throws {
        let mockAPI = MockAPIClient()
        mockAPI.responseData = JSONFixtures.validScanResult

        let mockProcessor = MockImageProcessor()
        let service = ScoringService(apiClient: mockAPI, imageProcessor: mockProcessor)

        let result = try await service.scoreRoom(image: UIImage())

        #expect(result.overallScore == 7.5)
        #expect(result.style == "Scandinavian")
        #expect(result.tips.count == 3)
        #expect(mockAPI.callCount == 1)
        #expect(mockAPI.lastEndpoint == "/score")
    }

    @Test("Retries on decode failure")
    func retriesOnDecodeFailure() async throws {
        let mockAPI = MockAPIClient()
        // First call returns invalid data, second returns valid
        let invalidData = JSONFixtures.invalidJSON
        let validData = JSONFixtures.validScanResult

        let retryAPI = RetryMockAPIClient(responses: [invalidData, validData])
        let mockProcessor = MockImageProcessor()
        let service = ScoringService(apiClient: retryAPI, imageProcessor: mockProcessor)

        let result = try await service.scoreRoom(image: UIImage())

        #expect(result.overallScore == 7.5)
        #expect(retryAPI.callCount == 2)
    }

    @Test("Throws on network error")
    func throwsOnNetworkError() async {
        let mockAPI = MockAPIClient()
        mockAPI.shouldThrow = APIError.networkError(URLError(.notConnectedToInternet))

        let mockProcessor = MockImageProcessor()
        let service = ScoringService(apiClient: mockAPI, imageProcessor: mockProcessor)

        do {
            _ = try await service.scoreRoom(image: UIImage())
            Issue.record("Expected error to be thrown")
        } catch {
            #expect(error is APIError)
        }
    }

    @Test("Throws on timeout")
    func throwsOnTimeout() async {
        let mockAPI = MockAPIClient()
        mockAPI.shouldThrow = APIError.timeout

        let mockProcessor = MockImageProcessor()
        let service = ScoringService(apiClient: mockAPI, imageProcessor: mockProcessor)

        do {
            _ = try await service.scoreRoom(image: UIImage())
            Issue.record("Expected timeout error")
        } catch let error as APIError {
            if case .timeout = error {
                // Expected
            } else {
                Issue.record("Expected timeout, got \(error)")
            }
        } catch {
            Issue.record("Expected APIError, got \(error)")
        }
    }
}

// MARK: - Test Helpers

private final class MockImageProcessor: ImageProcessorProtocol {
    nonisolated func prepare(_ image: UIImage) throws -> Data {
        Data(repeating: 0xFF, count: 100)
    }
}

private final class RetryMockAPIClient: APIClientProtocol, @unchecked Sendable {
    private var responses: [Data]
    private(set) var callCount = 0

    init(responses: [Data]) {
        self.responses = responses
    }

    func post(_ endpoint: String, body: Data) async throws -> Data {
        let index = min(callCount, responses.count - 1)
        callCount += 1
        return responses[index]
    }
}
