import SwiftUI

struct RecordsView: View {
    let store: DemoHealthDataStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HealthCard {
                        VStack(spacing: 10) {
                            Image(systemName: "doc.viewfinder")
                                .font(.system(size: 42, weight: .semibold))
                                .foregroundStyle(WellAllyColor.primary)
                            Text("records.scan.title")
                                .font(.title3.bold())
                            Text("records.scan.subtitle")
                                .font(.subheadline)
                                .foregroundStyle(WellAllyColor.secondaryText)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                        .background(WellAllyColor.primarySoft)
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

                        Text("records.preview.title")
                            .font(.headline)
                        PreviewField(name: "records.field.date", value: "2026-05-09")
                        PreviewField(name: "records.field.hospital", value: String(localized: "records.field.hospital.value"))
                        PreviewField(name: "records.field.type", value: String(localized: "category.biochemistry"))
                    }

                    HealthCard {
                        Text("records.timeline.title")
                            .font(.headline)
                        ForEach(store.records) { record in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(LocalizedStringKey(record.title))
                                        .font(.subheadline.weight(.semibold))
                                    Spacer()
                                    Text(LocalizedStringKey(record.category))
                                        .font(.caption.weight(.medium))
                                        .foregroundStyle(WellAllyColor.secondaryText)
                                }
                                Text(LocalizedStringKey(record.summary))
                                    .font(.caption)
                                    .foregroundStyle(WellAllyColor.secondaryText)
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }
                .padding(20)
            }
            .background(WellAllyColor.background)
            .navigationTitle("records.title")
        }
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
