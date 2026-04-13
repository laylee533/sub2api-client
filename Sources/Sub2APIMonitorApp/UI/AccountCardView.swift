import SwiftUI

struct AccountCardView: View {
    let card: AccountCardModel

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(card.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                    Text(metaLine)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Text("模型 \(card.modelDisplayText)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                Text(card.state.badgeTitle)
                    .font(.caption2)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(stateTint.opacity(0.14))
                    .foregroundStyle(stateTint)
                    .clipShape(Capsule())
            }

            ProgressStripe(
                title: "5h",
                utilization: card.fiveHourUtilization,
                countdown: card.fiveHourCountdownText,
                windowText: card.fiveHourWindowText
            )
            ProgressStripe(
                title: "7d",
                utilization: card.sevenDayUtilization,
                countdown: card.sevenDayCountdownText,
                windowText: card.sevenDayWindowText
            )
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.gray.opacity(0.16))
        )
    }

    private var metaLine: String {
        if card.currentConcurrency > 0 {
            return "使用中 · 并发 \(card.currentConcurrency)"
        }

        guard let lastUsedAt = card.lastUsedAt else {
            return "最近使用 -"
        }

        return "最近使用 \(relativeTime(lastUsedAt))"
    }

    private var stateTint: Color {
        switch card.state {
        case .inUse:
            .teal
        case .tight:
            .orange
        case .rateLimited:
            .orange
        case .unschedulable:
            .gray
        case .healthy:
            .gray
        }
    }

    private func relativeTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: .now)
    }
}
