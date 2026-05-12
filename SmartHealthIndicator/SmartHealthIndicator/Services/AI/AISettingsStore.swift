import Foundation
import Observation

@Observable
final class AISettingsStore {
    private static let configKey = "ai.provider.config"
    private static let keychainAccount = "ai.api.key"

    var config: AIProviderConfig
    var apiKeyStatus: String = "settings.api_key.not_saved"

    private let keychain: KeychainServing
    private let defaults: UserDefaults

    init(keychain: KeychainServing, defaults: UserDefaults = .standard) {
        self.keychain = keychain
        self.defaults = defaults
        if let data = defaults.data(forKey: Self.configKey),
           let decoded = try? JSONDecoder().decode(AIProviderConfig.self, from: data) {
            config = decoded
        } else {
            config = .default
        }
        refreshAPIKeyStatus()
    }

    func saveConfig() {
        var normalized = config
        normalized.applyProviderDefaultsIfNeeded()
        config = normalized
        if let data = try? JSONEncoder().encode(config) {
            defaults.set(data, forKey: Self.configKey)
        }
    }

    func saveAPIKey(_ key: String) throws {
        try keychain.save(key, account: Self.keychainAccount)
        refreshAPIKeyStatus()
    }

    func readAPIKey() throws -> String? {
        try keychain.read(account: Self.keychainAccount)
    }

    func clearAPIKey() throws {
        try keychain.delete(account: Self.keychainAccount)
        refreshAPIKeyStatus()
    }

    func makeClient() throws -> any LLMClient {
        guard let apiKey = try readAPIKey(), !apiKey.isEmpty else {
            throw LLMClientError.missingAPIKey
        }
        switch config.provider {
        case .openAICompatible:
            return OpenAICompatibleClient(apiKey: apiKey)
        case .anthropic:
            return AnthropicClient(apiKey: apiKey)
        }
    }

    private func refreshAPIKeyStatus() {
        apiKeyStatus = ((try? keychain.read(account: Self.keychainAccount)) ?? nil).map { _ in "settings.api_key.saved_in_keychain" } ?? "settings.api_key.not_saved"
    }
}
