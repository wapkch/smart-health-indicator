import XCTest
@testable import WellAllyIOS

final class AgentLoopTests: XCTestCase {
    func testAgentReturnsDirectAnswerWithoutTools() async throws {
        let loop = AgentLoop(
            client: StaticLLMClient(responses: [.text("Direct answer")]),
            config: .default,
            tools: HealthToolRegistry(store: DemoHealthDataStore())
        )

        let answer = try await loop.answer(question: "Summarize")
        XCTAssertEqual(answer.summary, "Direct answer")
        XCTAssertFalse(answer.safetyBoundary.isEmpty)
    }

    func testAgentExecutesToolThenReturnsFinalAnswer() async throws {
        let loop = AgentLoop(
            client: StaticLLMClient(responses: [
                LLMResponse(message: nil, toolCalls: [
                    LLMToolCall(id: "1", name: "get_indicator_trend", arguments: #"{"name":"LDL"}"#)
                ]),
                .text("Final answer")
            ]),
            config: .default,
            tools: HealthToolRegistry(store: DemoHealthDataStore())
        )

        let answer = try await loop.answer(question: "LDL?")
        XCTAssertEqual(answer.summary, "Final answer")
        XCTAssertTrue(answer.evidence.contains { $0.localizedCaseInsensitiveContains("ldl") })
    }

    func testAgentHandlesUnknownToolAsEvidence() async throws {
        let loop = AgentLoop(
            client: StaticLLMClient(responses: [
                LLMResponse(message: nil, toolCalls: [
                    LLMToolCall(id: "1", name: "unknown_tool", arguments: "{}")
                ]),
                .text("Recovered")
            ]),
            config: .default,
            tools: HealthToolRegistry(store: DemoHealthDataStore())
        )

        let answer = try await loop.answer(question: "Call unknown")
        XCTAssertEqual(answer.summary, "Recovered")
        XCTAssertTrue(answer.evidence.contains { $0.contains("unknown_tool") })
    }

    func testAgentStopsAfterMaxToolRounds() async throws {
        let loop = AgentLoop(
            client: AlwaysToolLLMClient(),
            config: .default,
            tools: HealthToolRegistry(store: DemoHealthDataStore()),
            maxToolRounds: 2
        )

        let answer = try await loop.answer(question: "Loop")
        XCTAssertFalse(answer.summary.isEmpty)
        XCTAssertEqual(answer.evidence.count, 2)
    }
}

struct StaticLLMClient: LLMClient {
    var responses: [LLMResponse]

    func send(_ request: LLMRequest) async throws -> LLMResponse {
        responses[min(request.messages.filter { $0.role == .tool }.count, responses.count - 1)]
    }
}

struct AlwaysToolLLMClient: LLMClient {
    func send(_ request: LLMRequest) async throws -> LLMResponse {
        LLMResponse(message: nil, toolCalls: [
            LLMToolCall(id: UUID().uuidString, name: "summarize_recent_reports", arguments: "{}")
        ])
    }
}
