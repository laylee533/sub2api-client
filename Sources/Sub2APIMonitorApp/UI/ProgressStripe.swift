import SwiftUI

struct ProgressStripe: View {
    let title: String
    let utilization: Double
    let countdown: String
    let windowText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Text(title)
                    .font(.caption2)
                    .fontWeight(.semibold)
                Text("\(Int(utilization * 100))%")
                    .font(.caption2)
                    .foregroundStyle(barColor)
                Spacer()
                Text(countdownLabel)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            GeometryReader { proxy in
                let width = max(0, min(utilization, 1.0)) * proxy.size.width

                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 999)
                        .fill(Color.gray.opacity(0.16))
                    RoundedRectangle(cornerRadius: 999)
                        .fill(barColor)
                        .frame(width: width)
                }
            }
            .frame(height: 5)

            Text(windowText.isEmpty ? "暂无窗口数据" : windowText)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }

    private var countdownLabel: String {
        countdown.isEmpty ? "--" : countdown
    }

    private var barColor: Color {
        if utilization >= 1.0 {
            return .red
        }
        if utilization >= 0.8 {
            return .orange
        }
        return .teal
    }
}
