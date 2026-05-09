import Foundation

struct AgentLoop: Sendable {
    var client: LLMClient
    var config: AIProviderConfig
    var tools: HealthToolRegistry
    var maxToolRounds: Int = 4

    func answer(question: String) async throws -> HealthAgentAnswer {
        var messages: [LLMMessage] = [
            .system("""
            You are Smart Health Indicator, a local-first health data assistant.
            You may explain records and trends, but you must not diagnose, prescribe medication, provide dosage, or replace a clinician.
            Return concise, evidence-backed answers.
            """),
            .user(question)
        ]

        for _ in 0..<maxToolRounds {
            let response = try await client.send(LLMRequest(config: config, messages: messages, tools: tools.toolDefinitions))
            if response.toolCalls.isEmpty {
                return makeAnswer(from: response.message?.content ?? String(localized: "agent.no_answer"), evidence: messages.filter { $0.role == .tool }.map(\.content))
            }

            for call in response.toolCalls {
                let output = await tools.execute(call)
                messages.append(.tool(id: call.id, content: output))
            }
        }

        return makeAnswer(
            from: String(localized: "agent.tool_limit"),
            evidence: messages.filter { $0.role == .tool }.map(\.content)
        )
    }

    private func makeAnswer(from text: String, evidence: [String]) -> HealthAgentAnswer {
        HealthAgentAnswer(
            summary: text,
            evidence: evidence.isEmpty ? ["agent.no_tool_evidence"] : evidence,
            safetyBoundary: "agent.safety_boundary",
            suggestedNextActions: [
                "agent.next.review_record",
                "agent.next.prepare_questions",
                "agent.next.urgent_care"
            ]
        )
    }
}

struct DemoLLMClient: LLMClient {
    func send(_ request: LLMRequest) async throws -> LLMResponse {
        let hasToolEvidence = request.messages.contains { $0.role == .tool }
        if hasToolEvidence {
            return .text(String(localized: "agent.demo.final_answer"))
        }
        return LLMResponse(
            message: nil,
            toolCalls: [
                LLMToolCall(id: "demo-tool-1", name: "get_indicator_trend", arguments: #"{"name":"LDL"}"#),
                LLMToolCall(id: "demo-tool-2", name: "summarize_recent_reports", arguments: "{}")
            ]
        )
    }
}
