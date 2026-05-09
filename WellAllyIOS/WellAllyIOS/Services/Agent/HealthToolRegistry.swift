import Foundation

struct HealthToolRegistry: Sendable {
    var store: HealthDataStore

    var toolDefinitions: [LLMTool] {
        [
            tool("search_health_records", "Search local health records by keyword.", ["query": "Search text. Empty means recent records."]),
            tool("get_indicator_trend", "Return trend data for a named health indicator.", ["name": "Indicator name, such as LDL."]),
            tool("summarize_recent_reports", "Summarize the most recent health reports.", [:]),
            tool("check_medication_interactions", "Check demo medication and allergy interaction context.", [:]),
            tool("prepare_doctor_summary", "Prepare a concise doctor visit summary.", [:])
        ]
    }

    func execute(_ call: LLMToolCall) async -> String {
        let arguments = parseArguments(call.arguments)
        switch call.name {
        case "search_health_records":
            let query = arguments["query"] ?? ""
            let results = store.searchRecords(query: query)
            return results.map { "\(AppLocalizer.string($0.category)): \(AppLocalizer.string($0.title)) - \(AppLocalizer.string($0.summary))" }.joined(separator: "\n")
        case "get_indicator_trend":
            let name = arguments["name"] ?? "LDL"
            guard let trend = store.indicatorTrend(named: name) else {
                return String(format: String(localized: "tool.trend.not_found_format"), name)
            }
            return String(
                format: String(localized: "tool.trend.result_format"),
                AppLocalizer.string(trend.name),
                trend.currentValue,
                trend.unit,
                trend.referenceRange,
                AppLocalizer.string(trend.interpretation)
            )
        case "summarize_recent_reports":
            return store.summarizeRecentReports()
        case "check_medication_interactions":
            return store.checkMedicationInteractions()
        case "prepare_doctor_summary":
            return store.prepareDoctorSummary()
        default:
            return String(format: String(localized: "tool.unknown_format"), call.name)
        }
    }

    private func tool(_ name: String, _ description: String, _ properties: [String: String]) -> LLMTool {
        var schemaProperties: [String: JSONValue] = [:]
        for (key, description) in properties {
            schemaProperties[key] = .object([
                "type": .string("string"),
                "description": .string(description)
            ])
        }
        return LLMTool(
            name: name,
            description: description,
            parameters: [
                "type": .string("object"),
                "properties": .object(schemaProperties),
                "additionalProperties": .bool(false)
            ]
        )
    }

    private func parseArguments(_ arguments: String) -> [String: String] {
        guard let data = arguments.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return [:]
        }
        return object.compactMapValues { $0 as? String }
    }
}
