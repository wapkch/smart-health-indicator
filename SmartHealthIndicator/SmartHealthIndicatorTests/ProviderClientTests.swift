import Foundation
import XCTest
@testable import SmartHealthIndicator

final class ProviderClientTests: XCTestCase {
    func testOpenAICompatibleRequestUsesConfiguredBaseURL() throws {
        let config = AIProviderConfig(
            provider: .openAICompatible,
            baseURLString: "https://openai-compatible.example.test/api",
            model: "model-a",
            temperature: 0.1,
            maxTokens: 512,
            enableTools: true
        )
        let client = OpenAICompatibleClient(apiKey: "key")
        let request = try client.makeRequest(
            LLMRequest(
                config: config,
                messages: [.user("hello")],
                tools: [LLMTool(name: "search_health_records", description: "Search", parameters: ["type": .string("object")])]
            )
        )

        XCTAssertEqual(request.url?.absoluteString, "https://openai-compatible.example.test/api/v1/chat/completions")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer key")

        let body = try XCTUnwrap(request.httpBody)
        let json = try JSONSerialization.jsonObject(with: body) as? [String: Any]
        XCTAssertEqual(json?["model"] as? String, "model-a")
        XCTAssertNotNil(json?["tools"])
    }

    func testAnthropicRequestUsesConfiguredBaseURL() throws {
        let config = AIProviderConfig(
            provider: .anthropic,
            baseURLString: "https://anthropic.example.test",
            model: "claude-test",
            temperature: 0.2,
            maxTokens: 300,
            enableTools: true
        )
        let client = AnthropicClient(apiKey: "key")
        let request = try client.makeRequest(
            LLMRequest(
                config: config,
                messages: [.system("safe"), .user("hello")],
                tools: [LLMTool(name: "summarize_recent_reports", description: "Summarize", parameters: ["type": .string("object")])]
            )
        )

        XCTAssertEqual(request.url?.absoluteString, "https://anthropic.example.test/v1/messages")
        XCTAssertEqual(request.value(forHTTPHeaderField: "x-api-key"), "key")
        XCTAssertEqual(request.value(forHTTPHeaderField: "anthropic-version"), "2023-06-01")

        let body = try XCTUnwrap(request.httpBody)
        let json = try JSONSerialization.jsonObject(with: body) as? [String: Any]
        XCTAssertEqual(json?["model"] as? String, "claude-test")
        XCTAssertEqual(json?["system"] as? String, "safe")
        XCTAssertNotNil(json?["tools"])
    }
}
