import Foundation

struct HealthProfile: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    var name: String
    var age: Int
    var role: String
    var focusAreas: [String]
}

struct HealthRecord: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    var title: String
    var category: String
    var date: Date
    var summary: String
    var tags: [String]
}

struct IndicatorPoint: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    var date: Date
    var value: Double
    var unit: String
}

struct IndicatorTrend: Codable, Equatable, Sendable {
    var name: String
    var currentValue: Double
    var unit: String
    var referenceRange: String
    var points: [IndicatorPoint]
    var interpretation: String
}

struct HealthAgentAnswer: Codable, Equatable, Sendable {
    var summary: String
    var evidence: [String]
    var safetyBoundary: String
    var suggestedNextActions: [String]
}
