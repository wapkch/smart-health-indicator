import SwiftUI

struct HomeView: View {
    let store: DemoHealthDataStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HealthCard {
                        StatusPill(text: "home.status.ai_checked", tint: WellAllyColor.primary, background: WellAllyColor.primarySoft)
                        Text("home.risk.title")
                            .font(.title2.bold())
                            .foregroundStyle(WellAllyColor.text)
                        Text("home.risk.subtitle")
                            .foregroundStyle(WellAllyColor.secondaryText)

                        HStack(spacing: 10) {
                            MetricTile(title: "BMI", value: "22.9", tint: WellAllyColor.primary, background: WellAllyColor.primarySoft)
                            MetricTile(title: "BP", value: "126/78", tint: WellAllyColor.info, background: WellAllyColor.infoSoft)
                            MetricTile(title: "metric.sleep", value: String(localized: "metric.sleep.value"), tint: WellAllyColor.warning, background: WellAllyColor.warningSoft)
                        }
                    }

                    HealthCard {
                        Text("home.actions.title")
                            .font(.headline)
                        ActionRow(title: "home.action.upload_lipid", tint: WellAllyColor.info, background: WellAllyColor.infoSoft)
                        ActionRow(title: "home.action.log_sleep", tint: WellAllyColor.warning, background: WellAllyColor.warningSoft)
                        ActionRow(title: "home.action.review_interaction", tint: WellAllyColor.risk, background: WellAllyColor.riskSoft)
                    }

                    HealthCard {
                        Text("home.modules.title")
                            .font(.headline)
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            ModuleTile(title: "module.chronic", icon: "waveform.path.ecg", tint: WellAllyColor.primary)
                            ModuleTile(title: "module.sleep", icon: "moon", tint: WellAllyColor.warning)
                            ModuleTile(title: "module.fitness", icon: "figure.run", tint: WellAllyColor.info)
                            ModuleTile(title: "module.women", icon: "calendar", tint: WellAllyColor.risk)
                        }
                    }
                }
                .padding(20)
            }
            .background(WellAllyColor.background)
            .navigationTitle("home.title")
        }
    }
}

private struct ActionRow: View {
    var title: LocalizedStringKey
    var tint: Color
    var background: Color

    var body: some View {
        HStack {
            Image(systemName: "plus.circle.fill")
                .foregroundStyle(tint)
            Text(title)
                .fontWeight(.medium)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(background)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct ModuleTile: View {
    var title: LocalizedStringKey
    var icon: String
    var tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.title3.weight(.semibold))
                .foregroundStyle(tint)
            Text(title)
                .font(.subheadline.weight(.semibold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(WellAllyColor.background)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
