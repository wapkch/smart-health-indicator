import Foundation

enum AIProvider: String, Codable, CaseIterable, Identifiable, Sendable {
    case openAICompatible
    case anthropic

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .openAICompatible:
            String(localized: "provider.openai_compatible")
        case .anthropic:
            String(localized: "provider.anthropic")
        }
    }

    var defaultBaseURL: URL {
        switch self {
        case .openAICompatible:
            URL(string: "https://api.openai.com")!
        case .anthropic:
            URL(string: "https://api.anthropic.com")!
        }
    }

    var defaultModel: String {
        switch self {
        case .openAICompatible:
            "gpt-4.1-mini"
        case .anthropic:
            "claude-sonnet-4-5"
        }
    }
}

struct AIProviderConfig: Codable, Equatable, Sendable {
    var provider: AIProvider
    var baseURLString: String
    var model: String
    var temperature: Double
    var maxTokens: Int
    var enableTools: Bool

    static let `default` = AIProviderConfig(
        provider: .openAICompatible,
        baseURLString: AIProvider.openAICompatible.defaultBaseURL.absoluteString,
        model: AIProvider.openAICompatible.defaultModel,
        temperature: 0.2,
        maxTokens: 900,
        enableTools: true
    )

    var resolvedBaseURL: URL {
        URL(string: baseURLString.trimmingCharacters(in: .whitespacesAndNewlines))
            ?? provider.defaultBaseURL
    }

    mutating func applyProviderDefaultsIfNeeded() {
        if baseURLString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            baseURLString = provider.defaultBaseURL.absoluteString
        }
        if model.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            model = provider.defaultModel
        }
    }
}
