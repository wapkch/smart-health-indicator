import Foundation

struct OpenAICompatibleClient: LLMClient {
    var apiKey: String
    var session: URLSessionProtocol = URLSession.shared

    func send(_ request: LLMRequest) async throws -> LLMResponse {
        let urlRequest = try makeRequest(request)
        let (data, response) = try await session.data(for: urlRequest)
        try validate(response: response, data: data)
        return try OpenAIResponseMapper.map(data)
    }

    func makeRequest(_ request: LLMRequest) throws -> URLRequest {
        guard !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw LLMClientError.missingAPIKey
        }

        let url = request.config.resolvedBaseURL.appendingAPIPath("v1/chat/completions")
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let body = OpenAIChatRequest(
            model: request.config.model,
            messages: request.messages.map(OpenAIChatMessage.init),
            temperature: request.config.temperature,
            maxTokens: request.config.maxTokens,
            tools: request.config.enableTools ? request.tools.map(OpenAIChatTool.init) : nil
        )
        urlRequest.httpBody = try JSONEncoder().encode(body)
        return urlRequest
    }

    private func validate(response: URLResponse, data: Data) throws {
        guard let response = response as? HTTPURLResponse else {
            throw LLMClientError.invalidResponse
        }
        guard (200..<300).contains(response.statusCode) else {
            throw LLMClientError.httpStatus(response.statusCode, String(data: data, encoding: .utf8) ?? "")
        }
    }
}

private struct OpenAIChatRequest: Encodable {
    var model: String
    var messages: [OpenAIChatMessage]
    var temperature: Double
    var maxTokens: Int
    var tools: [OpenAIChatTool]?

    enum CodingKeys: String, CodingKey {
        case model
        case messages
        case temperature
        case maxTokens = "max_tokens"
        case tools
    }
}

private struct OpenAIChatMessage: Codable {
    var role: String
    var content: String
    var toolCallID: String?

    init(_ message: LLMMessage) {
        role = message.role.rawValue
        content = message.content
        toolCallID = message.toolCallID
    }

    enum CodingKeys: String, CodingKey {
        case role
        case content
        case toolCallID = "tool_call_id"
    }
}

private struct OpenAIChatTool: Encodable {
    var type = "function"
    var function: FunctionSpec

    init(_ tool: LLMTool) {
        function = FunctionSpec(name: tool.name, description: tool.description, parameters: tool.parameters)
    }

    struct FunctionSpec: Encodable {
        var name: String
        var description: String
        var parameters: [String: JSONValue]
    }
}

enum OpenAIResponseMapper {
    static func map(_ data: Data) throws -> LLMResponse {
        let response = try JSONDecoder().decode(OpenAIChatResponse.self, from: data)
        guard let choice = response.choices.first else {
            throw LLMClientError.invalidResponse
        }

        let message = choice.message.content.map(LLMMessage.assistant)
        let calls = choice.message.toolCalls?.map {
            LLMToolCall(id: $0.id, name: $0.function.name, arguments: $0.function.arguments)
        } ?? []
        return LLMResponse(message: message, toolCalls: calls)
    }
}

private struct OpenAIChatResponse: Decodable {
    var choices: [Choice]

    struct Choice: Decodable {
        var message: Message
    }

    struct Message: Decodable {
        var content: String?
        var toolCalls: [ToolCall]?

        enum CodingKeys: String, CodingKey {
            case content
            case toolCalls = "tool_calls"
        }
    }

    struct ToolCall: Decodable {
        var id: String
        var function: Function
    }

    struct Function: Decodable {
        var name: String
        var arguments: String
    }
}
