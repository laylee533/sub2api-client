import SwiftUI

struct DashboardModelList: View {
    let items: [DashboardModelItem]

    var body: some View {
        if items.isEmpty {
            ContentUnavailableView("暂无模型分布", systemImage: "chart.bar")
                .frame(maxWidth: .infinity, minHeight: 180)
        } else {
            LazyVStack(spacing: 8) {
                ForEach(items) { item in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(alignment: .firstTextBaseline) {
                            Text(item.modelName)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .lineLimit(1)
                            Spacer()
                            Text("\(Int(item.ratio * 100))%")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.teal)
                        }

                        GeometryReader { proxy in
                            let width = max(0, min(item.ratio, 1.0)) * proxy.size.width

                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 999)
                                    .fill(Color.gray.opacity(0.14))
                                RoundedRectangle(cornerRadius: 999)
                                    .fill(Color.teal)
                                    .frame(width: width)
                            }
                        }
                        .frame(height: 6)

                        HStack {
                            Text("\(compact(item.tokenCount)) Token")
                            Spacer()
                            Text("\(money(item.actualCost))")
                        }
                        .font(.caption2)
                        .foregroundStyle(.secondary)
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
