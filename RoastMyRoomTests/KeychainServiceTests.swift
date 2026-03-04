import Testing
import Foundation
@testable import RoastMyRoom

@Suite("MockKeychainService — In-memory Keychain")
struct KeychainServiceTests {

    @Test("Stores and retrieves string")
    func stringStorage() {
        let keychain = MockKeychainService()
        keychain.set("hello", forKey: "test_key")

        #expect(keychain.get(forKey: "test_key") == "hello")
    }

    @Test("Returns nil for missing key")
    func missingKey() {
        let keychain = MockKeychainService()

        #expect(keychain.get(forKey: "nonexistent") == nil)
    }

    @Test("Stores and retrieves Int")
    func intStorage() {
        let keychain = MockKeychainService()
        keychain.set(42, forKey: "count")

        #expect(keychain.getInt(forKey: "count") == 42)
    }

    @Test("Stores and retrieves Date")
    func dateStorage() {
        let keychain = MockKeychainService()
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        keychain.set(date, forKey: "timestamp")

        let retrieved = keychain.getDate(forKey: "timestamp")
        #expect(retrieved != nil)
        #expect(abs((retrieved?.timeIntervalSince1970 ?? 0) - 1_700_000_000) < 1)
    }

    @Test("Stores and retrieves Bool")
    func boolStorage() {
        let keychain = MockKeychainService()
        keychain.set(true, forKey: "flag")

        #expect(keychain.getBool(forKey: "flag") == true)

        keychain.set(false, forKey: "flag")
        #expect(keychain.getBool(forKey: "flag") == false)
    }

    @Test("Delete removes key")
    func deleteKey() {
        let keychain = MockKeychainService()
        keychain.set("value", forKey: "key")
        keychain.delete(forKey: "key")

        #expect(keychain.get(forKey: "key") == nil)
    }

    @Test("Overwrite replaces value")
    func overwrite() {
        let keychain = MockKeychainService()
        keychain.set("first", forKey: "key")
        keychain.set("second", forKey: "key")

        #expect(keychain.get(forKey: "key") == "second")
    }
}
