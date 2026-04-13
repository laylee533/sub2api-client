import Foundation
import Testing
@testable import Sub2APIMonitorApp

@Test
@MainActor
func appModelDefaultsToAccountsTabModelsDashboardTabAndAllFilter() {
    let model = AppModel()

    #expect(model.selectedTab == .accounts)
    #expect(model.selectedDashboardSubtab == .models)
    #expect(model.selectedFilter == .all)
}

@Test
@MainActor
func high5hFilterIncludesAccountsAboveSixtyPercent() {
    let model = AppModel()
    model.cards = [
        AccountCardModel(
            id: 1,
            name: "high",
            state: .tight,
            currentConcurrency: 0,
            lastUsedAt: nil,
            fiveHourUtilization: 0.63,
            fiveHourCountdownText: "4h 20m",
            sevenDayUtilization: 0.50,
            sevenDayCountdownText: "2d"
        ),
        AccountCardModel(
            id: 2,
            name: "low",
            state: .healthy,
            currentConcurrency: 0,
            lastUsedAt: nil,
            fiveHourUtilization: 0.59,
            fiveHourCountdownText: "4h 50m",
            sevenDayUtilization: 0.20,
            sevenDayCountdownText: "5d"
        )
    ]
    model.selectedFilter = .high5h

    #expect(model.filteredCards.map(\.name) == ["high"])
}

@Test
@MainActor
func abnormalFilterOnlyIncludesRateLimitedAndUnschedulableAccounts() {
    let model = AppModel()
    model.cards = [
        AccountCardModel(
            id: 1,
            name: "rate-limited",
            state: .rateLimited,
            currentConcurrency: 0,
            lastUsedAt: nil,
            fiveHourUtilization: 1,
            fiveHourCountdownText: "1h",
            sevenDayUtilization: 0.4,
            sevenDayCountdownText: "2d"
        ),
        AccountCardModel(
            id: 2,
            name: "unschedulable",
            state: .unschedulable,
            currentConcurrency: 0,
            lastUsedAt: nil,
            fiveHourUtilization: 0.2,
            fiveHourCountdownText: "2h",
            sevenDayUtilization: 0.3,
            sevenDayCountdownText: "3d"
        ),
        AccountCardModel(
            id: 3,
            name: "tight",
            state: .tight,
            currentConcurrency: 0,
            lastUsedAt: nil,
            fiveHourUtilization: 0.7,
            fiveHourCountdownText: "3h",
            sevenDayUtilization: 0.6,
            sevenDayCountdownText: "4d"
        ),
        AccountCardModel(
            id: 4,
            name: "healthy",
            state: .healthy,
            currentConcurrency: 0,
            lastUsedAt: nil,
            fiveHourUtilization: 0.2,
            fiveHourCountdownText: "4h",
            sevenDayUtilization: 0.1,
            sevenDayCountdownText: "5d"
        )
    ]
    model.selectedFilter = .abnormal

    #expect(model.filteredCards.map(\.name) == ["rate-limited", "unschedulable"])
}
