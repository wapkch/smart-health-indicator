import SwiftUI

enum WellAllyColor {
    static let background = Color(red: 0.965, green: 0.973, blue: 0.969)
    static let surface = Color.white
    static let text = Color(red: 0.090, green: 0.129, blue: 0.114)
    static let secondaryText = Color(red: 0.384, green: 0.439, blue: 0.416)
    static let primary = Color(red: 0.118, green: 0.541, blue: 0.416)
    static let primarySoft = Color(red: 0.867, green: 0.949, blue: 0.918)
    static let info = Color(red: 0.204, green: 0.431, blue: 0.741)
    static let infoSoft = Color(red: 0.890, green: 0.929, blue: 0.984)
    static let warning = Color(red: 0.722, green: 0.475, blue: 0.094)
    static let warningSoft = Color(red: 1.000, green: 0.945, blue: 0.831)
    static let risk = Color(red: 0.776, green: 0.290, blue: 0.290)
    static let riskSoft = Color(red: 1.000, green: 0.902, blue: 0.902)
}

struct HealthCard<Content: View>: View {
    var content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(WellAllyColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.06), radius: 16, y: 8)
    }
}

struct StatusPill: View {
    var text: LocalizedStringKey
    var tint: Color
    var background: Color

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(background)
            .clipShape(Capsule())
    }
}

struct MetricTile: View {
    var title: LocalizedStringKey
    var value: String
    var tint: Color
    var background: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(tint)
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(WellAllyColor.text)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(background)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
