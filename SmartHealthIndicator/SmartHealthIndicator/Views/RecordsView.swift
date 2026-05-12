import SwiftUI

struct RecordsView: View {
    let store: DemoHealthDataStore

    @State private var filters = RecordFilterState()
    @State private var isShowingEntryOptions = false

    private var filteredRecords: [HealthRecord] {
        filters.apply(to: store.records)
    }

    private var availableTags: [String] {
        Array(Set(store.records.flatMap(\.tags))).sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    RecordEntryCard(showEntryOptions: { isShowingEntryOptions = true })
                    RecordSearchField(text: $filters.query)
                    RecordFilterControls(filters: $filters, availableTags: availableTags)
                    RecordTimelineSection(
                        records: filteredRecords,
                        resultCount: filteredRecords.count,
                        clearFilters: { filters.reset() }
                    )
                }
                .padding(20)
            }
            .background(WellAllyColor.background)
            .navigationTitle("records.title")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isShowingEntryOptions = true
                    } label: {
                        Image(systemName: "doc.badge.plus")
                    }
                    .accessibilityLabel("records.entry.add")
                }
            }
            .confirmationDialog("records.entry.title", isPresented: $isShowingEntryOptions, titleVisibility: .visible) {
                Button("records.entry.scan") {}
                Button("records.entry.manual") {}
                Button("records.entry.import_file") {}
            } message: {
                Text("records.entry.message")
            }
        }
    }
}

struct RecordFilterState: Equatable {
    var query = ""
    var category: RecordCategoryFilter = .all
    var dateRange: RecordDateRange = .all
    var selectedTag: String?
    var sortOrder: RecordSortOrder = .newestFirst

    var hasActiveFilters: Bool {
        !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || category != .all
            || dateRange != .all
            || selectedTag != nil
            || sortOrder != .newestFirst
    }

    mutating func reset() {
        self = RecordFilterState()
    }

    func apply(to records: [HealthRecord], now: Date = Date()) -> [HealthRecord] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let filtered = records.filter { record in
            category.matches(record)
                && dateRange.contains(record.date, now: now)
                && matchesTag(record)
                && matchesQuery(trimmedQuery, record: record)
        }

        switch sortOrder {
        case .newestFirst:
            return filtered.sorted { $0.date > $1.date }
        case .oldestFirst:
            return filtered.sorted { $0.date < $1.date }
        }
    }

    private func matchesTag(_ record: HealthRecord) -> Bool {
        guard let selectedTag else { return true }
        return record.tags.contains { $0.caseInsensitiveCompare(selectedTag) == .orderedSame }
    }

    private func matchesQuery(_ query: String, record: HealthRecord) -> Bool {
        guard !query.isEmpty else { return true }
        let searchableParts = [
            AppLocalizer.string(record.title),
            AppLocalizer.string(record.category),
            AppLocalizer.string(record.summary),
            record.title,
            record.category,
            record.summary
        ] + record.tags

        return searchableParts.contains { $0.localizedCaseInsensitiveContains(query) }
    }
}

enum RecordCategoryFilter: String, CaseIterable, Identifiable {
    case all
    case biochemistry
    case imaging
    case medication

    var id: String { rawValue }

    var titleKey: LocalizedStringKey {
        switch self {
        case .all: "records.filter.all"
        case .biochemistry: "category.biochemistry"
        case .imaging: "category.imaging"
        case .medication: "category.medication"
        }
    }

    private var categoryKey: String? {
        switch self {
        case .all: nil
        case .biochemistry: "category.biochemistry"
        case .imaging: "category.imaging"
        case .medication: "category.medication"
        }
    }

    func matches(_ record: HealthRecord) -> Bool {
        guard let categoryKey else { return true }
        return record.category == categoryKey
    }
}

enum RecordDateRange: String, CaseIterable, Identifiable {
    case all
    case last7Days
    case last30Days

    var id: String { rawValue }

    var titleKey: LocalizedStringKey {
        switch self {
        case .all: "records.filter.all"
        case .last7Days: "records.filter.last_7_days"
        case .last30Days: "records.filter.last_30_days"
        }
    }

    func contains(_ date: Date, now: Date) -> Bool {
        switch self {
        case .all:
            return true
        case .last7Days:
            return date >= Calendar.current.date(byAdding: .day, value: -7, to: now) ?? now
        case .last30Days:
            return date >= Calendar.current.date(byAdding: .day, value: -30, to: now) ?? now
        }
    }
}

enum RecordSortOrder: String, CaseIterable, Identifiable {
    case newestFirst
    case oldestFirst

    var id: String { rawValue }

    var titleKey: LocalizedStringKey {
        switch self {
        case .newestFirst: "records.sort.newest"
        case .oldestFirst: "records.sort.oldest"
        }
    }
}

private struct RecordEntryCard: View {
    let showEntryOptions: () -> Void

    var body: some View {
        Button {
            showEntryOptions()
        } label: {
            HealthCard {
                HStack(spacing: 14) {
                    Image(systemName: "doc.viewfinder")
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundStyle(WellAllyColor.primary)
                        .frame(width: 48, height: 48)
                        .background(WellAllyColor.primarySoft)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                    VStack(alignment: .leading, spacing: 4) {
                        Text("records.scan.title")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(WellAllyColor.text)
                        Text("records.scan.subtitle")
                            .font(.caption)
                            .foregroundStyle(WellAllyColor.secondaryText)
                    }

                    Spacer()

                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(WellAllyColor.primary)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

private struct RecordSearchField: View {
    @Binding var text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(WellAllyColor.secondaryText)
            TextField("records.search.placeholder", text: $text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(WellAllyColor.secondaryText)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("records.search.clear")
            }
        }
        .padding(14)
        .background(WellAllyColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 12, y: 6)
    }
}

private struct RecordFilterControls: View {
    @Binding var filters: RecordFilterState
    let availableTags: [String]

    var body: some View {
        HealthCard {
            VStack(alignment: .leading, spacing: 14) {
                Picker("records.filter.category", selection: $filters.category) {
                    ForEach(RecordCategoryFilter.allCases) { option in
                        Text(option.titleKey).tag(option)
                    }
                }
                .pickerStyle(.segmented)

                Picker("records.filter.date", selection: $filters.dateRange) {
                    ForEach(RecordDateRange.allCases) { option in
                        Text(option.titleKey).tag(option)
                    }
                }
                .pickerStyle(.segmented)

                HStack(spacing: 12) {
                    Menu {
                        Button("records.filter.all") {
                            filters.selectedTag = nil
                        }
                        ForEach(availableTags, id: \.self) { tag in
                            Button(tag) {
                                filters.selectedTag = tag
                            }
                        }
                    } label: {
                        FilterMenuLabel(
                            title: "records.filter.tag",
                            value: filters.selectedTag ?? String(localized: "records.filter.all"),
                            systemImage: "tag"
                        )
                    }

                    Picker("records.sort.title", selection: $filters.sortOrder) {
                        ForEach(RecordSortOrder.allCases) { option in
                            Text(option.titleKey).tag(option)
                        }
                    }
                    .pickerStyle(.menu)
                    .buttonStyle(.bordered)
                }

                if filters.hasActiveFilters {
                    Button {
                        filters.reset()
                    } label: {
                        Label("records.filter.clear", systemImage: "arrow.counterclockwise")
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(WellAllyColor.primary)
                }
            }
        }
    }
}

private struct FilterMenuLabel: View {
    var title: LocalizedStringKey
    var value: String
    var systemImage: String

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(WellAllyColor.secondaryText)
                Text(value)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(WellAllyColor.text)
                    .lineLimit(1)
            }
        } icon: {
            Image(systemName: systemImage)
                .foregroundStyle(WellAllyColor.primary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(WellAllyColor.primarySoft)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct RecordTimelineSection: View {
    let records: [HealthRecord]
    let resultCount: Int
    let clearFilters: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("records.timeline.title")
                    .font(.headline)
                Spacer()
                Text(String(format: String(localized: "records.result_count_format"), resultCount))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(WellAllyColor.secondaryText)
            }

            if records.isEmpty {
                RecordEmptyState(clearFilters: clearFilters)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(records) { record in
                        NavigationLink {
                            RecordDetailView(record: record)
                        } label: {
                            RecordRow(record: record)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

private struct RecordRow: View {
    let record: HealthRecord

    var body: some View {
        HealthCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text(LocalizedStringKey(record.title))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(WellAllyColor.text)
                        .lineLimit(2)
                    Spacer(minLength: 8)
                    Text(record.date.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption.weight(.medium))
                        .foregroundStyle(WellAllyColor.secondaryText)
                }

                HStack(spacing: 8) {
                    StatusPill(text: LocalizedStringKey(record.category), tint: WellAllyColor.info, background: WellAllyColor.infoSoft)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(WellAllyColor.secondaryText)
                }

                Text(LocalizedStringKey(record.summary))
                    .font(.caption)
                    .foregroundStyle(WellAllyColor.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)

                TagFlow(tags: record.tags)
            }
        }
    }
}

private struct RecordDetailView: View {
    let record: HealthRecord

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HealthCard {
                    VStack(alignment: .leading, spacing: 12) {
                        StatusPill(text: LocalizedStringKey(record.category), tint: WellAllyColor.info, background: WellAllyColor.infoSoft)
                        Text(LocalizedStringKey(record.title))
                            .font(.title2.bold())
                            .foregroundStyle(WellAllyColor.text)
                            .fixedSize(horizontal: false, vertical: true)
                        PreviewField(name: "records.field.date", value: record.date.formatted(date: .long, time: .omitted))
                    }
                }

                HealthCard {
                    Text("records.detail.summary")
                        .font(.headline)
                    Text(LocalizedStringKey(record.summary))
                        .font(.body)
                        .foregroundStyle(WellAllyColor.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }

                HealthCard {
                    Text("records.detail.tags")
                        .font(.headline)
                    TagFlow(tags: record.tags)
                }
            }
            .padding(20)
        }
        .background(WellAllyColor.background)
        .navigationTitle("records.detail.title")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct TagFlow: View {
    let tags: [String]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(tags, id: \.self) { tag in
                    Text(tag)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(WellAllyColor.primary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(WellAllyColor.primarySoft)
                        .clipShape(Capsule())
                }
            }
        }
    }
}

private struct RecordEmptyState: View {
    let clearFilters: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(WellAllyColor.secondaryText)
            Text("records.empty.title")
                .font(.headline)
            Text("records.empty.subtitle")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(WellAllyColor.secondaryText)
            Button {
                clearFilters()
            } label: {
                Label("records.filter.clear", systemImage: "arrow.counterclockwise")
            }
            .buttonStyle(.borderedProminent)
            .tint(WellAllyColor.primary)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(WellAllyColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct PreviewField: View {
    var name: LocalizedStringKey
    var value: String

    var body: some View {
        HStack {
            Text(name)
                .foregroundStyle(WellAllyColor.secondaryText)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .font(.subheadline)
    }
}
