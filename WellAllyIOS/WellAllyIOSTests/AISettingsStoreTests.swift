import XCTest
@testable import WellAllyIOS

final class AISettingsStoreTests: XCTestCase {
    func testConfigPersistsToDefaults() {
        let defaults = UserDefaults(suiteName: "AISettingsStoreTests-\(UUID().uuidString)")!
        let keychain = InMemoryKeychainService()
        let store = AISettingsStore(keychain: keychain, defaults: defaults)

        store.config.provider = .anthropic
        store.config.baseURLString = "https://anthropic.example.test"
        store.config.model = "claude-test"
        store.saveConfig()

        let reloaded = AISettingsStore(keychain: keychain, defaults: defaults)
        XCTAssertEqual(reloaded.config.provider, .anthropic)
        XCTAssertEqual(reloaded.config.baseURLString, "https://anthropic.example.test")
        XCTAssertEqual(reloaded.config.model, "claude-test")
    }

    func testAPIKeyCanBeSavedReadAndCleared() throws {
        let store = AISettingsStore(
            keychain: InMemoryKeychainService(),
            defaults: UserDefaults(suiteName: "AISettingsStoreTests-\(UUID().uuidString)")!
        )

        try store.saveAPIKey("test-key")
        XCTAssertEqual(try store.readAPIKey(), "test-key")
        XCTAssertEqual(store.apiKeyStatus, "settings.api_key.saved_in_keychain")

        try store.clearAPIKey()
        XCTAssertNil(try store.readAPIKey())
        XCTAssertEqual(store.apiKeyStatus, "settings.api_key.not_saved")
    }
}

final class InMemoryKeychainService: KeychainServing, @unchecked Sendable {
    private var values: [String: String] = [:]

    func save(_ value: String, account: String) throws {
        values[account] = value
    }

    func read(account: String) throws -> String? {
        values[account]
    }

    func delete(account: String) throws {
        values.removeValue(forKey: account)
    }
}
