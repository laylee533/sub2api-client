import Foundation
import Testing
@testable import Sub2APIMonitorApp

@Test
func activeAccountsSortBeforeTightAccounts() {
    let active = AccountCardModel(
        id: 1,
        name: "team-1",
        state: .inUse,
        currentConcurrency: 1,
        lastUsedAt: .now,
        fiveHourUtilization: 0.14,
        fiveHourCountdownText: "4h 30m",
        sevenDayUtilization: 0.74,
        sevenDayCountdownText: "23h 11m"
    )
    let tight = AccountCardModel(
        id: 2,
        name: "team-2",
        state: .tight,
        currentConcurrency: 0,
        lastUsedAt: .now,
        fiveHourUtilization: 0.81,
        fiveHourCountdownText: "12m",
        sevenDayUtilization: 0.40,
        sevenDayCountdownText: "2d 2h"
    )

    let sorted = [tight, active].sorted(by: AccountCardModel.sortForDisplay)
    #expect(sorted.first?.state == .inUse)
}

@Test
func tighterFiveHourUtilizationSortsFirstInsideSameBucket() {
    let referenceDate = Date(timeIntervalSince1970: 1_711_111_111)
    let high = AccountCardModel(
        id: 3,
        name: "high",
        state: .tight,
        currentConcurrency: 0,
        lastUsedAt: referenceDate,
        fiveHourUtilization: 0.90,
        fiveHourCountdownText: "8m",
        sevenDayUtilization: 0.30,
        sevenDayCountdownText: "1d 6h"
    )
    let low = AccountCardModel(
        id: 4,
        name: "low",
        state: .tight,
        currentConcurrency: 0,
        lastUsedAt: referenceDate,
        fiveHourUtilization: 0.81,
        fiveHourCountdownText: "28m",
        sevenDayUtilization: 0.50,
        sevenDayCountdownText: "3d 1h"
    )

    let sorted = [low, high].sorted(by: AccountCardModel.sortForDisplay)
    #expect(sorted.first?.name == "high")
}

@Test
func healthyAccountsSortBeforeUnavailableAccounts() {
    let healthy = AccountCardModel(
        id: 5,
        name: "healthy",
        state: .healthy,
        currentConcurrency: 0,
        lastUsedAt: .now,
        fiveHourUtilization: 0.10,
        fiveHourCountdownText: "4h 10m",
        sevenDayUtilization: 0.20,
        sevenDayCountdownText: "5d"
    )
    let unschedulable = AccountCardModel(
        id: 6,
        name: "unsched",
        state: .unschedulable,
        currentConcurrency: 0,
        lastUsedAt: nil,
        fiveHourUtilization: 0,
        fiveHourCountdownText: "",
        sevenDayUtilization: 0,
        sevenDayCountdownText: ""
    )

    let sorted = [unschedulable, healthy].sorted(by: AccountCardModel.sortForDisplay)
    #expect(sorted.first?.state == .healthy)
}

@Test
func moreRecentlyUsedCardsSortBeforeHigherUtilizationInsideSameStateBucket() {
    let recent = AccountCardModel(
        id: 7,
        name: "recent",
        state: .healthy,
        currentConcurrency: 0,
        lastUsedAt: .now,
        fiveHourUtilization: 0.35,
        fiveHourCountdownText: "3h 40m",
        sevenDayUtilization: 0.20,
        sevenDayCountdownText: "5d",
        modelDisplayText: "gpt-5.4"
    )
    let stale = AccountCardModel(
        id: 8,
        name: "stale",
        state: .healthy,
        currentConcurrency: 0,
        lastUsedAt: .now.addingTimeInterval(-7_200),
        fiveHourUtilization: 0.89,
        fiveHourCountdownText: "40m",
        sevenDayUtilization: 0.70,
        sevenDayCountdownText: "2d",
        modelDisplayText: "gpt-5.4-mini"
    )

    let sorted = [stale, recent].sorted(by: AccountCardModel.sortForDisplay)
    #expect(sorted.first?.name == "recent")
}
