import Foundation

enum MockFixtures {
    static let summary = SiteSummary(
        siteName: "demo.sub2api.org",
        baseURL: URL(string: "https://demo.sub2api.org")!,
        totalAccounts: 27,
        todayTokens: 22_500_000,
        totalTokens: 126_000_000,
        todayActualCost: 31.8,
        todayStandardCost: 39.6,
        totalActualCost: 502.4,
        totalStandardCost: 618.9,
        lastRefreshedAt: .now
    )

    static let cards: [AccountCardModel] = [
        AccountCardModel(
            id: 1,
            name: "team-1",
            state: .inUse,
            currentConcurrency: 1,
            lastUsedAt: .now,
            fiveHourUtilization: 0.14,
            fiveHourCountdownText: "4h 30m",
            fiveHourWindowText: "已用 14% · 剩余 86%",
            sevenDayUtilization: 0.74,
            sevenDayCountdownText: "23h 11m",
            sevenDayWindowText: "已用 74% · 剩余 26%"
        ),
        AccountCardModel(
            id: 3,
            name: "team-3",
            state: .inUse,
            currentConcurrency: 2,
            lastUsedAt: .now,
            fiveHourUtilization: 0.21,
            fiveHourCountdownText: "4h 41m",
            fiveHourWindowText: "已用 21% · 剩余 79%",
            sevenDayUtilization: 0.50,
            sevenDayCountdownText: "4d 21h",
            sevenDayWindowText: "已用 50% · 剩余 50%"
        ),
        AccountCardModel(
            id: 2,
            name: "team-2",
            state: .tight,
            currentConcurrency: 0,
            lastUsedAt: .now.addingTimeInterval(-24 * 60),
            fiveHourUtilization: 0.72,
            fiveHourCountdownText: "8m",
            fiveHourWindowText: "已用 72% · 剩余 28%",
            sevenDayUtilization: 0.80,
            sevenDayCountdownText: "18h 48m",
            sevenDayWindowText: "已用 80% · 剩余 20%"
        ),
        AccountCardModel(
            id: 4,
            name: "team-4",
            state: .rateLimited,
            currentConcurrency: 0,
            lastUsedAt: .now.addingTimeInterval(-14 * 60),
            fiveHourUtilization: 1.0,
            fiveHourCountdownText: "3h 45m",
            fiveHourWindowText: "已用 100% · 剩余 0%",
            sevenDayUtilization: 0.47,
            sevenDayCountdownText: "4d 18h",
            sevenDayWindowText: "已用 47% · 剩余 53%"
        )
    ]

    static let dashboardModels: [DashboardModelItem] = [
        DashboardModelItem(
            modelName: "gpt-4.1-mini",
            tokenCount: 14_800_000,
            actualCost: 18.6,
            ratio: 0.66
        ),
        DashboardModelItem(
            modelName: "claude-3.7-sonnet",
            tokenCount: 7_700_000,
            actualCost: 13.2,
            ratio: 0.34
        )
    ]

    static let dashboardUserRanking: [DashboardUserRankingItem] = [
        DashboardUserRankingItem(
            displayName: "team-3",
            tokenCount: 9_200_000,
            actualCost: 12.8,
            standardCost: 15.1,
            primaryModel: "gpt-4.1-mini"
        ),
        DashboardUserRankingItem(
            displayName: "team-1",
            tokenCount: 6_400_000,
            actualCost: 8.7,
            standardCost: 11.4,
            primaryModel: "claude-3.7-sonnet"
        )
    ]

    static let primaryModelName = dashboardModels.first?.modelName ?? "-"
}
