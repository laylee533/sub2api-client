import SwiftUI

struct AccountMonitorTabView: View {
    @Bindable var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SiteSummarySection(summary: model.summary)
            FilterChipRow(selectedFilter: model.selectedFilter) { model.selectedFilter = $0 }
            AccountCardGrid(cards: model.filteredCards)

            Button("在浏览器中打开站点") {
                model.openSiteHome()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
