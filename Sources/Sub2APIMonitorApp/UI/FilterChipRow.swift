import SwiftUI

struct FilterChipRow: View {
    let selectedFilter: FilterMode
    let onSelect: (FilterMode) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(FilterMode.allCases, id: \.self) { filter in
                    Button(title(for: filter)) {
                        onSelect(filter)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(filter == selectedFilter ? Color.teal : Color.white)
                    .foregroundStyle(filter == selectedFilter ? Color.white : Color.primary)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.gray.opacity(filter == selectedFilter ? 0 : 0.2)))
                }
            }
        }
    }

    private func title(for filter: FilterMode) -> String {
        switch filter {
        case .abnormal:
            return "不可用"
        default:
            return filter.title
        }
    }
}
