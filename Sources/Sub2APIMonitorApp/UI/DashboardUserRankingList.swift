import SwiftUI

struct DashboardUserRankingList: View {
    let items: [DashboardUserRankingItem]

    var body: some View {
        if items.isEmpty {
            ContentUnavailableView("暂无用户消费榜", systemImage: "person.3")
                .frame(maxWidth: .infinity, minHeight: 180)
        } else {
            LazyVStack(spacing: 8) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    HStack(alignment: .top, spacing: 10) {
                        Text("\(index + 1)")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .frame(width: 22, height: 22)
                            .background(Color.teal.opacity(0.12))
                            .foregroundStyle(.teal)
                            .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.displayName)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .lineLimit(1)
                            Text(item.primaryModel)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)

                            HStack {
                                Text("今日 \(money(item.actualCost))")
                                Spacer()
                                Text("\(compact(item.tokenCount)) Token")
                            }
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        }
                    }
                    .padding(10)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.gray.opacity(0.16)))
                }
            }
        }
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
        String(format: "%.1f", value)
    }
}
