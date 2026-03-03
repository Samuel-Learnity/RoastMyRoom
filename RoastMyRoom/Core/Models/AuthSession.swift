import Foundation

struct AuthSession: Codable, Sendable {
    let accessToken: String
    let refreshToken: String
    let userId: String
    let expiresAt: Date

    var isExpired: Bool {
        Date() >= expiresAt
    }
}
