import AuthenticationServices
import Foundation

@MainActor
protocol AuthServiceProtocol: AnyObject {
    var isAuthenticated: Bool { get }
    var currentUserId: String? { get }
    var accessToken: String? { get }
    var userEmail: String? { get }
    func signInWithApple() async throws
    func signOut()
    func refreshSessionIfNeeded() async
}

enum AuthError: Error, LocalizedError {
    case appleSignInFailed
    case missingIdentityToken
    case supabaseAuthFailed(String)
    case refreshFailed

    var errorDescription: String? {
        switch self {
        case .appleSignInFailed:
            return String(localized: "auth_error_apple_sign_in")
        case .missingIdentityToken:
            return String(localized: "auth_error_missing_token")
        case .supabaseAuthFailed(let detail):
            return String(localized: "auth_error_supabase \(detail)")
        case .refreshFailed:
            return String(localized: "auth_error_refresh")
        }
    }
}

@MainActor
final class AuthService: AuthServiceProtocol {
    nonisolated let apiBaseURL: String
    nonisolated let apiKey: String
    private let keychain: KeychainServiceProtocol

    private static let accessTokenKey = "auth_access_token"
    private static let refreshTokenKey = "auth_refresh_token"
    private static let userIdKey = "auth_user_id"
    private static let expiresAtKey = "auth_expires_at"
    private static let userEmailKey = "auth_user_email"

    private(set) var isAuthenticated = false
    private(set) var currentUserId: String?
    private(set) var accessToken: String?
    private(set) var userEmail: String?
    private var refreshToken: String?
    private var expiresAt: Date?

    init(keychainService: KeychainServiceProtocol, apiBaseURL: String, apiKey: String) {
        self.keychain = keychainService
        self.apiBaseURL = apiBaseURL
        self.apiKey = apiKey
        loadSession()
    }

    // MARK: - Session Persistence

    private func loadSession() {
        guard let token = keychain.get(forKey: Self.accessTokenKey),
              let refresh = keychain.get(forKey: Self.refreshTokenKey),
              let userId = keychain.get(forKey: Self.userIdKey) else {
            return
        }

        accessToken = token
        refreshToken = refresh
        currentUserId = userId
        expiresAt = keychain.getDate(forKey: Self.expiresAtKey)
        userEmail = keychain.get(forKey: Self.userEmailKey)
        isAuthenticated = true
    }

    private func saveSession(_ session: AuthSession, email: String?) {
        keychain.set(session.accessToken, forKey: Self.accessTokenKey)
        keychain.set(session.refreshToken, forKey: Self.refreshTokenKey)
        keychain.set(session.userId, forKey: Self.userIdKey)
        keychain.set(session.expiresAt, forKey: Self.expiresAtKey)
        if let email {
            keychain.set(email, forKey: Self.userEmailKey)
        }

        accessToken = session.accessToken
        refreshToken = session.refreshToken
        currentUserId = session.userId
        expiresAt = session.expiresAt
        userEmail = email ?? userEmail
        isAuthenticated = true
    }

    private func clearSession() {
        keychain.delete(forKey: Self.accessTokenKey)
        keychain.delete(forKey: Self.refreshTokenKey)
        keychain.delete(forKey: Self.userIdKey)
        keychain.delete(forKey: Self.expiresAtKey)
        keychain.delete(forKey: Self.userEmailKey)

        accessToken = nil
        refreshToken = nil
        currentUserId = nil
        expiresAt = nil
        userEmail = nil
        isAuthenticated = false
    }

    // MARK: - Sign In with Apple

    func signInWithApple() async throws {
        let (idToken, email) = try await performAppleSignIn()
        let session = try await exchangeTokenWithSupabase(idToken: idToken)
        saveSession(session, email: email)
    }

    private func performAppleSignIn() async throws -> (idToken: String, email: String?) {
        try await withCheckedThrowingContinuation { continuation in
            let delegate = AppleSignInDelegate(continuation: continuation)
            let provider = ASAuthorizationAppleIDProvider()
            let request = provider.createRequest()
            request.requestedScopes = [.fullName, .email]

            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = delegate
            // Keep strong reference via associated object until callback fires
            objc_setAssociatedObject(controller, "delegate", delegate, .OBJC_ASSOCIATION_RETAIN)
            controller.performRequests()
        }
    }

    private func exchangeTokenWithSupabase(idToken: String) async throws -> AuthSession {
        guard let url = URL(string: "\(apiBaseURL)/auth/v1/token?grant_type=id_token") else {
            throw AuthError.supabaseAuthFailed("Invalid URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "apikey")

        let body: [String: String] = [
            "provider": "apple",
            "id_token": idToken
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("[AuthService] ❌ Supabase auth failed: \(errorBody)")
            throw AuthError.supabaseAuthFailed(errorBody)
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]

        guard let accessToken = json["access_token"] as? String,
              let refreshToken = json["refresh_token"] as? String,
              let user = json["user"] as? [String: Any],
              let userId = user["id"] as? String else {
            throw AuthError.supabaseAuthFailed("Invalid response format")
        }

        let expiresIn = json["expires_in"] as? Int ?? 3600
        let expiresAt = Date().addingTimeInterval(TimeInterval(expiresIn))

        return AuthSession(
            accessToken: accessToken,
            refreshToken: refreshToken,
            userId: userId,
            expiresAt: expiresAt
        )
    }

    // MARK: - Refresh

    func refreshSessionIfNeeded() async {
        guard isAuthenticated,
              let currentRefreshToken = refreshToken else { return }

        // Only skip refresh if we have a known expiry that's still fresh
        if let expiry = expiresAt, Date() < expiry.addingTimeInterval(-300) {
            return
        }

        do {
            let session = try await refreshAccessToken(refreshToken: currentRefreshToken)
            saveSession(session, email: nil)
            print("[AuthService] ✅ Token refreshed")
        } catch {
            print("[AuthService] ⚠️ Refresh failed, clearing session: \(error)")
            clearSession()
        }
    }

    private func refreshAccessToken(refreshToken: String) async throws -> AuthSession {
        guard let url = URL(string: "\(apiBaseURL)/auth/v1/token?grant_type=refresh_token") else {
            throw AuthError.refreshFailed
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "apikey")

        let body: [String: String] = ["refresh_token": refreshToken]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw AuthError.refreshFailed
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]

        guard let newAccessToken = json["access_token"] as? String,
              let newRefreshToken = json["refresh_token"] as? String,
              let user = json["user"] as? [String: Any],
              let userId = user["id"] as? String else {
            throw AuthError.refreshFailed
        }

        let expiresIn = json["expires_in"] as? Int ?? 3600
        let expiresAt = Date().addingTimeInterval(TimeInterval(expiresIn))

        return AuthSession(
            accessToken: newAccessToken,
            refreshToken: newRefreshToken,
            userId: userId,
            expiresAt: expiresAt
        )
    }

    // MARK: - Sign Out

    func signOut() {
        clearSession()
    }
}

// MARK: - Apple Sign In Delegate

private final class AppleSignInDelegate: NSObject, ASAuthorizationControllerDelegate, @unchecked Sendable {
    private let continuation: CheckedContinuation<(idToken: String, email: String?), Error>
    private var hasResumed = false

    init(continuation: CheckedContinuation<(idToken: String, email: String?), Error>) {
        self.continuation = continuation
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard !hasResumed else { return }
        hasResumed = true

        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let tokenData = credential.identityToken,
              let idToken = String(data: tokenData, encoding: .utf8) else {
            continuation.resume(throwing: AuthError.missingIdentityToken)
            return
        }

        let email = credential.email
        continuation.resume(returning: (idToken: idToken, email: email))
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        guard !hasResumed else { return }
        hasResumed = true
        continuation.resume(throwing: AuthError.appleSignInFailed)
    }
}
