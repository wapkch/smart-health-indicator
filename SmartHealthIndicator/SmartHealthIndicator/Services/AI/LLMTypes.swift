import Foundation

enum LLMRole: String, Codable, Equatable, Sendable {
    case system
    case user
    case assistant
    case tool
}

struct LLMMessage: Codable, Equatable, Sendable {
    var role: LLMRole
    var content: String
    var toolCallID: String?

    static func system(_ content: String) -> LLMMessage {
        LLMMessage(role: .system, content: content, toolCallID: nil)
    }

    static func user(_ content: String) -> LLMMessage {
        LLMMessage(role: .user, content: content, toolCallID: nil)
    }

    static func assistant(_ content: String) -> LLMMessage {
        LLMMessage(role: .assistant, content: content, toolCallID: nil)
    }

    static func tool(id: String, content: String) -> LLMMessage {
        LLMMessage(role: .tool, content: content, toolCallID: id)
    }
}

struct LLMTool: Codable, Equatable, Sendable {
    var name: String
    var description: String
    var parameters: [String: JSONValue]
}

struct LLMToolCall: Codable, Equatable, Sendable {
    var id: String
    var name: String
    var arguments: String
}

struct LLMRequest: Codable, Equatable, Sendable {
    var config: AIProviderConfig
    var messages: [LLMMessage]
    var tools: [LLMTool]
}

struct LLMResponse: Codable, Equatable, Sendable {
    var message: LLMMessage?
    var toolCalls: [LLMToolCall]

    static func text(_ content: String) -> LLMResponse {
        LLMResponse(message: .assistant(content), toolCalls: [])
    }
}

protocol LLMClient: Sendable {
    func send(_ request: LLMRequest) async throws -> LLMResponse
}

enum LLMClientError: LocalizedError, Equatable {
    case invalidResponse
    case httpStatus(Int, String)
    case missingAPIKey

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            "The model provider returned an invalid response."
        case .httpStatus(let status, let body):
            "The model provider returned HTTP \(status): \(body)"
        case .missingAPIKey:
            "API key is required before calling the model provider."
        }
    }
}
