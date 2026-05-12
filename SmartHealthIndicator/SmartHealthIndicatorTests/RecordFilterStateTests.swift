import XCTest
@testable import SmartHealthIndicator

final class RecordFilterStateTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    func testQuerySearchesTitleSummaryCategoryAndTags() {
        let records = DemoHealthDataStore(now: now).records

        let ldlResults = RecordFilterState(query: "LDL").apply(to: records, now: now)
        XCTAssertEqual(ldlResults.map(\.title), ["record.ldl.title"])

        let tagResults = RecordFilterState(query: "radiation").apply(to: records, now: now)
        XCTAssertEqual(tagResults.map(\.title), ["record.ct.title"])
    }

    func testCategoryDateAndTagFiltersCanCombine() {
        let records = DemoHealthDataStore(now: now).records

        let matching = RecordFilterState(
            category: .biochemistry,
            dateRange: .last7Days,
            selectedTag: "follow-up"
        ).apply(to: records, now: now)
        XCTAssertEqual(matching.map(\.title), ["record.ldl.title"])

        let empty = RecordFilterState(
            category: .imaging,
            dateRange: .last7Days
        ).apply(to: records, now: now)
        XCTAssertTrue(empty.isEmpty)
    }

    func testSortOrderControlsTimelineOrder() {
        let records = DemoHealthDataStore(now: now).records

        let newest = RecordFilterState(sortOrder: .newestFirst).apply(to: records, now: now)
        XCTAssertEqual(newest.map(\.title), ["record.ldl.title", "record.ct.title", "record.allergy.title"])

        let oldest = RecordFilterState(sortOrder: .oldestFirst).apply(to: records, now: now)
        XCTAssertEqual(oldest.map(\.title), ["record.allergy.title", "record.ct.title", "record.ldl.title"])
    }

    func testResetClearsAllActiveFilters() {
        var filters = RecordFilterState(
            query: "LDL",
            category: .biochemistry,
            dateRange: .last30Days,
            selectedTag: "follow-up",
            sortOrder: .oldestFirst
        )

        XCTAssertTrue(filters.hasActiveFilters)
        filters.reset()
        XCTAssertEqual(filters, RecordFilterState())
        XCTAssertFalse(filters.hasActiveFilters)
    }
}
