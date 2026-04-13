import SwiftUI

struct DashboardSummaryStrip: View {
    let summary: SiteSummary
    let primaryModelName: String
    let activeModelCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                metric(title: "今日实际金额", value: money(summary.todayActualCost))
                metric(title: "今日标准金额", value: money(summary.todayStandardCost))
            }

            HStack(spacing: 8) {
                metric(title: "活跃模型", value: "\(activeModelCount)")
                metric(title: "主消耗模型", value: primaryModelName)
            }
        }
    }

    private func metric(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.gray.opacity(0.16)))
    }

    private func money(_ value: Double) -> String {
        String(format: "%.1f", value)
    }
}
