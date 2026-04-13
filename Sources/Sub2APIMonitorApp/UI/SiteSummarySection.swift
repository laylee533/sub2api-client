import SwiftUI

struct SiteSummarySection: View {
    let summary: SiteSummary

    var body: some View {
        HStack(spacing: 8) {
            metric(
                title: "今日 Token",
                tokenValue: compact(summary.todayTokens),
                actualCost: summary.todayActualCost,
                standardCost: summary.todayStandardCost
            )
            metric(
                title: "总 Token",
                tokenValue: compact(summary.totalTokens),
                actualCost: summary.totalActualCost,
                standardCost: summary.totalStandardCost
            )
        }
    }

    private func metric(title: String, tokenValue: String, actualCost: Double, standardCost: Double) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)

            HStack(alignment: .top, spacing: 10) {
                Text(tokenValue)
                    .font(.headline)
                    .lineLimit(1)

                Spacer(minLength: 0)

                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(money(actualCost)) / \(money(standardCost))")
                        .font(.caption)
                        .fontWeight(.semibold)
                    Text("实际 / 标准")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.gray.opacity(0.16)))
    }

    private func compact(_ value: Int) -> String {
        if value >= 1_000_000 {
            return String(format: "%.1fM", Double(value) / 1_000_000)
        }
        if value >= 1_000 {
            return String(format: "%.1fK", Double(value) / 1_000)
        }
        return "\(value)"
    }

    private func money(_ value: Double) -> String {
        if value >= 1_000 {
            return String(format: "%.1fk", value / 1_000)
        }
        return String(format: "%.1f", value)
    }
}
