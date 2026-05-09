import Foundation

struct AnthropicClient: LLMClient {
    var apiKey: String
    var session: URLSessionProtocol = URLSession.shared

    func send(_ request: LLMRequest) async throws -> LLMResponse {
        let urlRequest = try makeRequest(request)
        let (data, response) = try await session.data(for: urlRequest)
        try validate(response: response, data: data)
        return try AnthropicResponseMapper.map(data)
    }

    func makeRequest(_ request: LLMRequest) throws -> URLRequest {
        guard !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw LLMClientError.missingAPIKey
        }

        let url = request.config.resolvedBaseURL.appendingAPIPath("v1/messages")
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        urlRequest.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

        let system = request.messages.first(where: { $0.role == .system })?.content
        let body = AnthropicMessagesRequest(
            model: request.config.model,
            maxTokens: request.config.maxTokens,
            temperature: request.config.temperature,
            system: system,
            messages: request.messages.filter { $0.role != .system }.map(AnthropicMessage.init),
            tools: request.config.enableTools ? request.tools.map(AnthropicTool.init) : nil
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

private struct AnthropicMessagesRequest: Encodable {
    var model: String
    var maxTokens: Int
    var temperature: Double
    var system: String?
    var messages: [AnthropicMessage]
    var tools: [AnthropicTool]?

    enum CodingKeys: String, CodingKey {
        case model
        case maxTokens = "max_tokens"
        case temperature
        case system
        case messages
        case tools
    }
}

private struct AnthropicMessage: Encodable {
    var role: String
    var content: String

    init(_ message: LLMMessage) {
        role = message.role == .assistant ? "assistant" : "user"
        if message.role == .tool {
            content = "Tool result \(message.toolCallID ?? ""): \(message.content)"
        } else {
            content = message.content
        }
    }
}

private struct AnthropicTool: Encodable {
    var name: String
    var description: String
    var inputSchema: [String: JSONValue]

    init(_ tool: LLMTool) {
        name = tool.name
        description = tool.description
        inputSchema = tool.parameters
    }

    enum CodingKeys: String, CodingKey {
        case name
        case description
        case inputSchema = "input_schema"
    }
}

enum AnthropicResponseMapper {
    static func map(_ data: Data) throws -> LLMResponse {
        let response = try JSONDecoder().decode(AnthropicMessagesResponse.self, from: data)
        var textParts: [String] = []
        var calls: [LLMToolCall] = []

        for item in response.content {
            switch item.type {
            case "text":
                if let text = item.text {
                    textParts.append(text)
                }
            case "tool_use":
                calls.append(
                    LLMToolCall(
                        id: item.id ?? UUID().uuidString,
                        name: item.name ?? "",
                        arguments: item.input.flatMap { String(data: (try? JSONEncoder().encode($0)) ?? Data(), encoding: .utf8) } ?? "{}"
                    )
                )
            default:
                continue
            }
        }

        return LLMResponse(
            message: textParts.isEmpty ? nil : .assistant(textParts.joined(separator: "\n")),
            toolCalls: calls
        )
    }
}

private struct AnthropicMessagesResponse: Decodable {
    var content: [Content]

    struct Content: Decodable {
        var type: String
        var text: String?
        var id: String?
        var name: String?
        var input: [String: JSONValue]?
    }
}
