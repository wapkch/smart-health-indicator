import SwiftUI

struct SettingsView: View {
    @Environment(AISettingsStore.self) private var settings
    @Environment(\.dismiss) private var dismiss

    @State private var apiKey = ""
    @State private var statusMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                @Bindable var settings = settings

                Section("settings.provider.section") {
                    Picker("settings.protocol", selection: $settings.config.provider) {
                        ForEach(AIProvider.allCases) { provider in
                            Text(provider.displayName).tag(provider)
                        }
                    }

                    TextField("settings.base_url", text: $settings.config.baseURLString)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)

                    TextField("settings.model", text: $settings.config.model)
                        .textInputAutocapitalization(.never)

                    Toggle("settings.enable_tools", isOn: $settings.config.enableTools)
                }

                Section("settings.api_key.section") {
                    SecureField("settings.api_key.placeholder", text: $apiKey)
                    Text(LocalizedStringKey(settings.apiKeyStatus))
                        .foregroundStyle(.secondary)

                    HStack {
                        Button("settings.save_key") {
                            saveKey()
                        }
                        Button("settings.clear_key", role: .destructive) {
                            clearKey()
                        }
                    }
                }

                Section("settings.generation.section") {
                    Stepper(String(format: String(localized: "settings.max_tokens_format"), settings.config.maxTokens), value: $settings.config.maxTokens, in: 128...8000, step: 128)
                    Slider(value: $settings.config.temperature, in: 0...1)
                    Text(String(format: String(localized: "settings.temperature_format"), settings.config.temperature))
                        .foregroundStyle(.secondary)
                }

                if let statusMessage {
                    Section {
                        Text(statusMessage)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("settings.title")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("settings.done") {
                        settings.saveConfig()
                        dismiss()
                    }
                }
            }
            .onChange(of: settings.config) { _, _ in
                settings.saveConfig()
            }
        }
    }

    private func saveKey() {
        do {
            try settings.saveAPIKey(apiKey)
            apiKey = ""
            statusMessage = String(localized: "settings.api_key.saved")
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    private func clearKey() {
        do {
            try settings.clearAPIKey()
            statusMessage = String(localized: "settings.api_key.removed")
        } catch {
            statusMessage = error.localizedDescription
        }
    }
}

struct PreviewKeychainService: KeychainServing {
    func save(_ value: String, account: String) throws {}
    func read(account: String) throws -> String? { nil }
    func delete(account: String) throws {}
}
