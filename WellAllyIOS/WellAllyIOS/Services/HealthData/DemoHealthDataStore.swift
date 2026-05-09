import Foundation

protocol HealthDataStore: Sendable {
    var profiles: [HealthProfile] { get }
    var records: [HealthRecord] { get }
    func searchRecords(query: String) -> [HealthRecord]
    func indicatorTrend(named name: String) -> IndicatorTrend?
    func summarizeRecentReports() -> String
    func checkMedicationInteractions() -> String
    func prepareDoctorSummary() -> String
}

struct DemoHealthDataStore: HealthDataStore {
    let profiles: [HealthProfile]
    let records: [HealthRecord]
    let trends: [String: IndicatorTrend]

    init(now: Date = Date()) {
        profiles = [
            HealthProfile(id: UUID(), name: "profile.me", age: 35, role: "profile.role.adult", focusAreas: ["LDL", "module.sleep", "module.fitness"]),
            HealthProfile(id: UUID(), name: "profile.mom", age: 64, role: "profile.role.chronic_care", focusAreas: ["indicator.blood_pressure", "category.medication"]),
            HealthProfile(id: UUID(), name: "profile.child", age: 6, role: "profile.role.growth_curve", focusAreas: ["indicator.growth", "indicator.vaccines"])
        ]

        records = [
            HealthRecord(id: UUID(), title: "record.ldl.title", category: "category.biochemistry", date: now.addingTimeInterval(-2 * 86_400), summary: "record.ldl.summary", tags: ["LDL", "follow-up"]),
            HealthRecord(id: UUID(), title: "record.ct.title", category: "category.imaging", date: now.addingTimeInterval(-9 * 86_400), summary: "record.ct.summary", tags: ["CT", "radiation"]),
            HealthRecord(id: UUID(), title: "record.allergy.title", category: "category.medication", date: now.addingTimeInterval(-20 * 86_400), summary: "record.allergy.summary", tags: ["allergy", "medication"])
        ]

        let ldlPoints = [3.1, 3.2, 3.3, 3.5, 3.7].enumerated().map { offset, value in
            IndicatorPoint(id: UUID(), date: now.addingTimeInterval(Double(offset - 4) * 30 * 86_400), value: value, unit: "mmol/L")
        }
        trends = [
            "LDL": IndicatorTrend(
                name: "indicator.ldl_cholesterol",
                currentValue: 3.7,
                unit: "mmol/L",
                referenceRange: "< 3.4 mmol/L",
                points: ldlPoints,
                interpretation: "indicator.ldl.interpretation"
            )
        ]
    }

    func searchRecords(query: String) -> [HealthRecord] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return records }
        return records.filter {
            $0.title.localizedCaseInsensitiveContains(trimmed)
                || $0.category.localizedCaseInsensitiveContains(trimmed)
                || $0.tags.contains { $0.localizedCaseInsensitiveContains(trimmed) }
        }
    }

    func indicatorTrend(named name: String) -> IndicatorTrend? {
        trends[name] ?? trends.first { $0.key.localizedCaseInsensitiveContains(name) || $0.value.name.localizedCaseInsensitiveContains(name) }?.value
    }

    func summarizeRecentReports() -> String {
        records
            .sorted { $0.date > $1.date }
            .prefix(3)
            .map { "\(AppLocalizer.string($0.category)): \(AppLocalizer.string($0.title)) - \(AppLocalizer.string($0.summary))" }
            .joined(separator: "\n")
    }

    func checkMedicationInteractions() -> String {
        AppLocalizer.string("tool.medication_interactions.demo")
    }

    func prepareDoctorSummary() -> String {
        AppLocalizer.string("tool.doctor_summary.demo")
    }
}
