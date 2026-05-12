import SwiftUI

struct FamilyView: View {
    let store: DemoHealthDataStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HealthCard {
                        Text("family.profiles.title")
                            .font(.headline)
                        ForEach(store.profiles) { profile in
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(WellAllyColor.primarySoft)
                                    .frame(width: 44, height: 44)
                                    .overlay(Text(String(profile.name.prefix(1))).fontWeight(.bold).foregroundStyle(WellAllyColor.primary))
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(LocalizedStringKey(profile.name))
                                        .font(.subheadline.weight(.semibold))
                                    Text(String(format: String(localized: "family.profile.subtitle_format"), profile.age, AppLocalizer.string(profile.role)))
                                        .font(.caption)
                                        .foregroundStyle(WellAllyColor.secondaryText)
                                }
                                Spacer()
                            }
                        }
                    }

                    HealthCard {
                        StatusPill(text: "family.local_only", tint: WellAllyColor.primary, background: WellAllyColor.primarySoft)
                        Text("family.privacy.title")
                            .font(.title3.bold())
                        Text("family.privacy.subtitle")
                            .foregroundStyle(WellAllyColor.secondaryText)
                        PrivacyRow(title: "family.privacy.encrypted_key", value: "status.on")
                        PrivacyRow(title: "family.privacy.cloud_sync", value: "status.off")
                        PrivacyRow(title: "family.privacy.doctor_summary", value: "status.ready")
                    }
                }
                .padding(20)
            }
            .background(WellAllyColor.background)
            .navigationTitle("family.title")
        }
    }
}

private struct PrivacyRow: View {
    var title: LocalizedStringKey
    var value: String

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(LocalizedStringKey(value))
                .fontWeight(.semibold)
                .foregroundStyle(value == "status.off" ? WellAllyColor.secondaryText : WellAllyColor.primary)
        }
        .font(.subheadline)
    }
}
