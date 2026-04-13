import SwiftUI

struct DashboardTabView: View {
    @Bindable var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            DashboardSummaryStrip(
                summary: model.summary,
                primaryModelName: model.primaryModelName,
                activeModelCount: model.dashboardModels.count
            )

            DashboardModelList(items: model.dashboardModels)
        }
    }
}
