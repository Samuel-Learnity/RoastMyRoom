import Foundation
import Security

protocol KeychainServiceProtocol: Sendable {
    func set(_ value: String, forKey key: String)
    func get(forKey key: String) -> String?
    func set(_ value: Int, forKey key: String)
    func getInt(forKey key: String) -> Int?
    func set(_ value: Date, forKey key: String)
    func getDate(forKey key: String) -> Date?
    func set(_ value: Bool, forKey key: String)
    func getBool(forKey key: String) -> Bool?
    func delete(forKey key: String)
}

final class KeychainService: KeychainServiceProtocol {
    private let service: String

    init(service: String = Bundle.main.bundleIdentifier ?? "com.disco.RoastMyRoom") {
        self.service = service
    }

    // MARK: - String

    func set(_ value: String, forKey key: String) {
        guard let data = value.data(using: .utf8) else { return }
        delete(forKey: key)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            print("[Keychain] ⚠️ Failed to set \(key): \(status)")
        }
    }

    func get(forKey key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data else {
            return nil
        }

        return String(data: data, encoding: .utf8)
    }

    // MARK: - Int

    func set(_ value: Int, forKey key: String) {
        set(String(value), forKey: key)
    }

    func getInt(forKey key: String) -> Int? {
        guard let string = get(forKey: key) else { return nil }
        return Int(string)
    }

    // MARK: - Date

    func set(_ value: Date, forKey key: String) {
        let timestamp = String(value.timeIntervalSince1970)
        set(timestamp, forKey: key)
    }

    func getDate(forKey key: String) -> Date? {
        guard let string = get(forKey: key),
              let interval = Double(string) else { return nil }
        return Date(timeIntervalSince1970: interval)
    }

    // MARK: - Bool

    func set(_ value: Bool, forKey key: String) {
        set(value ? "1" : "0", forKey: key)
    }

    func getBool(forKey key: String) -> Bool? {
        guard let string = get(forKey: key) else { return nil }
        return string == "1"
    }

    // MARK: - Delete

    func delete(forKey key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]

        SecItemDelete(query as CFDictionary)
    }
}
