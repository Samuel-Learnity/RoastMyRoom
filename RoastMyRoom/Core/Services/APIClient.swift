import Foundation

enum APIError: Error, LocalizedError {
    case invalidURL
    case networkError(Error)
    case serverError(Int)
    case invalidResponse
    case decodingError(Error)
    case timeout
    case rateLimited

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return String(localized: "error_invalid_url")
        case .networkError(let underlying):
            if let urlError = underlying as? URLError,
               urlError.code == .notConnectedToInternet || urlError.code == .dataNotAllowed {
                return String(localized: "error_no_network")
            }
            return String(localized: "error_network_generic")
        case .serverError:
            return String(localized: "error_server")
        case .invalidResponse:
            return String(localized: "error_invalid_response")
        case .decodingError:
            return String(localized: "error_decoding")
        case .timeout:
            return String(localized: "error_timeout")
        case .rateLimited:
            return String(localized: "error_rate_limited")
        }
    }
}

protocol APIClientProtocol: Sendable {
    func post(_ endpoint: String, body: Data) async throws -> Data
}

final class APIClient: APIClientProtocol, @unchecked Sendable {
    private let baseURL: String
    private let apiKey: String
    private let session: URLSession

    init(baseURL: String, apiKey: String) {
        self.baseURL = baseURL
        self.apiKey = apiKey

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        self.session = URLSession(configuration: config)
    }

    func post(_ endpoint: String, body: Data) async throws -> Data {
        guard let url = URL(string: baseURL + endpoint) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let base64 = body.base64EncodedString()
        let language = Bundle.main.preferredLocalizations.first ?? "en"
        #if DEBUG
        print("[APIClient] Language sent: \(language)")
        #endif
        let payload = try JSONSerialization.data(
            withJSONObject: ["image": base64, "language": language]
        )
        request.httpBody = payload

        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(for: request)
        } catch let error as URLError where error.code == .timedOut {
            #if DEBUG
            print("[APIClient] ⏱ Timeout for \(endpoint)")
            #endif
            throw APIError.timeout
        } catch {
            #if DEBUG
            print("[APIClient] ❌ Network error for \(endpoint): \(error)")
            #endif
            throw APIError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            #if DEBUG
            print("[APIClient] ❌ Invalid response (not HTTP) for \(endpoint)")
            #endif
            throw APIError.invalidResponse
        }

        #if DEBUG
        print("[APIClient] \(endpoint) → HTTP \(httpResponse.statusCode)")
        #endif

        switch httpResponse.statusCode {
        case 200...299:
            return data
        case 429:
            #if DEBUG
            print("[APIClient] ⚠️ Rate limited")
            #endif
            throw APIError.rateLimited
        default:
            #if DEBUG
            let body = String(data: data, encoding: .utf8) ?? "(no body)"
            print("[APIClient] ❌ Server error \(httpResponse.statusCode): \(body)")
            #endif
            throw APIError.serverError(httpResponse.statusCode)
        }
    }
}
