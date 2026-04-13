import Foundation
import Testing
@testable import Sub2APIMonitorApp

@Test
func aggregatorBuildsSiteSummaryAndPrioritizedCards() {
    let referenceDate = Date(timeIntervalSince1970: 1_710_000_000)
    let site = SiteConfiguration(
        name: "demo",
        baseURL: URL(string: "https://demo.example.com")!,
        adminToken: "token"
    )

    let accounts = [
        AdminAccountDTO(
            id: 1,
            name: "team-1",
            platform: "openai",
            type: "oauth",
            currentConcurrency: 1,
            status: "active",
            schedulable: true,
            lastUsedAt: referenceDate,
            rateLimitedAt: nil,
            rateLimitResetAt: nil,
            overloadUntil: nil,
            tempUnschedulableUntil: nil,
            errorMessage: nil
        ),
        AdminAccountDTO(
            id: 2,
            name: "team-2",
            platform: "openai",
            type: "oauth",
            currentConcurrency: 0,
            status: "active",
            schedulable: true,
            lastUsedAt: referenceDate.addingTimeInterval(-1_800),
            rateLimitedAt: .now,
            rateLimitResetAt: .now.addingTimeInterval(600),
            overloadUntil: nil,
            tempUnschedulableUntil: nil,
            errorMessage: nil
        )
    ]

    let dashboardStats = AdminDashboardStatsDTO(
        totalAccounts: 2,
        todayTokens: 1_358_100,
        totalTokens: 23_500_000,
        todayCost: 16.8,
        todayActualCost: 12.5,
        totalCost: 566.3,
        totalActualCost: 410.7
    )
    let dashboardSnapshot = AdminDashboardSnapshotDTO(
        stats: nil,
        models: [
            AdminDashboardModelDTO(model: "gpt-4.1-mini", tokens: 900_000, actualCost: 8.2, ratio: 0.62),
            AdminDashboardModelDTO(model: "gpt-4.1", tokens: 458_100, actualCost: 4.3, ratio: 0.38)
        ],
        usersTrend: [
            AdminDashboardUserRankingDTO(
                name: "team-2",
                tokens: 810_000,
                actualCost: 8.2,
                standardCost: 10.0,
                primaryModel: "gpt-4.1-mini"
            ),
            AdminDashboardUserRankingDTO(
                name: "team-1",
                tokens: 548_100,
                actualCost: 4.3,
                standardCost: 6.8,
                primaryModel: "gpt-4.1"
            )
        ]
    )

    let usages = [
        1: AccountUsageInfoDTO(
            updatedAt: referenceDate,
            fiveHour: AccountUsageProgressDTO(utilization: 14, resetsAt: nil, remainingSeconds: 16_200),
            sevenDay: AccountUsageProgressDTO(utilization: 74, resetsAt: nil, remainingSeconds: 83_460)
        ),
        2: AccountUsageInfoDTO(
            updatedAt: referenceDate,
            fiveHour: AccountUsageProgressDTO(utilization: 81, resetsAt: nil, remainingSeconds: 480),
            sevenDay: AccountUsageProgressDTO(utilization: 40, resetsAt: nil, remainingSeconds: 67_680)
        )
    ]

    let payload = DashboardAggregator(referenceDate: referenceDate).build(
        site: site,
        dashboardStats: dashboardStats,
        dashboardSnapshot: dashboardSnapshot,
        accounts: accounts,
        usages: usages
    )

    #expect(payload.summary.todayTokens == 1_358_100)
    #expect(payload.summary.totalTokens == 23_500_000)
    #expect(payload.summary.todayActualCost == 12.5)
    #expect(payload.summary.todayStandardCost == 16.8)
    #expect(payload.summary.totalActualCost == 410.7)
    #expect(payload.summary.totalStandardCost == 566.3)
    #expect(payload.cards.first?.name == "team-1")
    #expect(payload.cards.first?.fiveHourUtilization == 0.14)
    #expect(payload.cards.first?.fiveHourWindowText == "已用 14% · 剩余 86%")
    #expect(payload.cards.first?.sevenDayWindowText == "已用 74% · 剩余 26%")
    #expect(payload.cards.last?.state == .rateLimited)
    #expect(payload.primaryModelName == "gpt-4.1-mini")
}

@Test
func aggregatorTreatsRecentlyUsedAccountsAsInUseEvenWhenConcurrencyIsZeroAndFallsBackWhenUsageIsMissing() {
    let referenceDate = Date(timeIntervalSince1970: 1_710_000_000)
    let site = SiteConfiguration(
        name: "demo",
        baseURL: URL(string: "https://demo.example.com")!,
        adminToken: "token"
    )

    let accounts = [
        AdminAccountDTO(
            id: 1,
            name: "recently-used",
            platform: "openai",
            type: "oauth",
            currentConcurrency: 0,
            status: "active",
            schedulable: true,
            lastUsedAt: referenceDate.addingTimeInterval(-120),
            rateLimitedAt: nil,
            rateLimitResetAt: nil,
            overloadUntil: nil,
            tempUnschedulableUntil: nil,
            errorMessage: nil
        ),
        AdminAccountDTO(
            id: 2,
            name: "tight",
            platform: "openai",
            type: "oauth",
            currentConcurrency: 0,
            status: "active",
            schedulable: true,
            lastUsedAt: nil,
            rateLimitedAt: nil,
            rateLimitResetAt: nil,
            overloadUntil: nil,
            tempUnschedulableUntil: nil,
            errorMessage: nil
        )
    ]

    let dashboardStats = AdminDashboardStatsDTO(
        totalAccounts: 2,
        todayTokens: 100,
        totalTokens: 200,
        todayCost: 1.2,
        todayActualCost: 0.8,
        totalCost: 4.8,
        totalActualCost: 3.6
    )
    let dashboardSnapshot = AdminDashboardSnapshotDTO(stats: nil, models: [], usersTrend: [])

    let usages = [
        2: AccountUsageInfoDTO(
            updatedAt: referenceDate,
            fiveHour: AccountUsageProgressDTO(utilization: 78, resetsAt: nil, remainingSeconds: 1_200),
            sevenDay: AccountUsageProgressDTO(utilization: 85, resetsAt: nil, remainingSeconds: 200_000)
        )
    ]

    let payload = DashboardAggregator(referenceDate: referenceDate).build(
        site: site,
        dashboardStats: dashboardStats,
        dashboardSnapshot: dashboardSnapshot,
        accounts: accounts,
        usages: usages
    )

    #expect(payload.cards.first?.name == "recently-used")
    #expect(payload.cards.first?.state == .inUse)
    #expect(payload.cards.first?.fiveHourWindowText == "暂无 5h 数据")
    #expect(payload.cards.first?.sevenDayWindowText == "暂无 7d 数据")
}

@Test
func aggregatorBuildsDashboardModelRowsInDescendingRatioOrder() {
    let site = SiteConfiguration(
        name: "demo",
        baseURL: URL(string: "https://demo.example.com")!,
        adminToken: "token"
    )
    let dashboardStats = AdminDashboardStatsDTO(
        totalAccounts: 0,
        todayTokens: 100,
        totalTokens: 200,
        todayCost: 1.2,
        todayActualCost: 0.9,
        totalCost: 4.8,
        totalActualCost: 3.6
    )
    let dashboardSnapshot = AdminDashboardSnapshotDTO(
        stats: nil,
        models: [
            AdminDashboardModelDTO(model: "gpt-4.1", tokens: 40, actualCost: 1.0, ratio: 0.20),
            AdminDashboardModelDTO(model: "gpt-4.1-mini", tokens: 124, actualCost: 2.2, ratio: 0.62)
        ],
        usersTrend: []
    )

    let payload = DashboardAggregator().build(
        site: site,
        dashboardStats: dashboardStats,
        dashboardSnapshot: dashboardSnapshot,
        accounts: [],
        usages: [:]
    )

    #expect(payload.dashboardModels.map(\.modelName) == ["gpt-4.1-mini", "gpt-4.1"])
    #expect(payload.primaryModelName == "gpt-4.1-mini")
}

@Test
func aggregatorPrefersCodexSnapshotFieldsFromAccountExtraOverUsageEndpointFallback() {
    let referenceDate = Date(timeIntervalSince1970: 1_710_000_000)
    let site = SiteConfiguration(
        name: "demo",
        baseURL: URL(string: "https://demo.example.com")!,
        adminToken: "token"
    )
    let account = AdminAccountDTO(
        id: 7,
        name: "team-7",
        platform: "openai",
        type: "oauth",
        currentConcurrency: 1,
        status: "active",
        schedulable: true,
        lastUsedAt: referenceDate,
        rateLimitedAt: nil,
        rateLimitResetAt: nil,
        overloadUntil: nil,
        tempUnschedulableUntil: nil,
        errorMessage: nil,
        extra: AdminAccountExtraDTO(
            codex5hUsedPercent: 12,
            codex5hResetAfterSeconds: 3_600,
            codex7dUsedPercent: 64,
            codex7dResetAfterSeconds: 200_000,
            upstreamModel: "gpt-5.4",
            requestedModel: "gpt-5"
        )
    )
    let usages = [
        7: AccountUsageInfoDTO(
            updatedAt: referenceDate,
            fiveHour: AccountUsageProgressDTO(utilization: 88, resetsAt: nil, remainingSeconds: 200),
            sevenDay: AccountUsageProgressDTO(utilization: 91, resetsAt: nil, remainingSeconds: 100)
        )
    ]

    let payload = DashboardAggregator(referenceDate: referenceDate).build(
        site: site,
        dashboardStats: AdminDashboardStatsDTO(
            totalAccounts: 1,
            todayTokens: 1,
            totalTokens: 2,
            todayStandardCost: 0,
            todayActualCost: 0,
            totalStandardCost: 0,
            totalActualCost: 0
        ),
        dashboardSnapshot: AdminDashboardSnapshotDTO(),
        accounts: [account],
        usages: usages
    )

    #expect(payload.cards.first?.fiveHourUtilization == 0.12)
    #expect(payload.cards.first?.sevenDayUtilization == 0.64)
    #expect(payload.cards.first?.modelDisplayText == "gpt-5.4")
}

@Test
func aggregatorKeepsTopUsersSortedByActualCostDescending() {
    let site = SiteConfiguration(
        name: "demo",
        baseURL: URL(string: "https://demo.example.com")!,
        adminToken: "token"
    )
    let dashboardStats = AdminDashboardStatsDTO(
        totalAccounts: 0,
        todayTokens: 100,
        totalTokens: 200,
        todayCost: 1.2,
        todayActualCost: 0.9,
        totalCost: 4.8,
        totalActualCost: 3.6
    )
    let dashboardSnapshot = AdminDashboardSnapshotDTO(
        stats: nil,
        models: [],
        usersTrend: [
            AdminDashboardUserRankingDTO(
                name: "team-a",
                tokens: 410_000,
                actualCost: 3.1,
                standardCost: 4.0,
                primaryModel: "gpt-4.1"
            ),
            AdminDashboardUserRankingDTO(
                name: "team-b",
                tokens: 820_000,
                actualCost: 8.4,
                standardCost: 10.5,
                primaryModel: "gpt-4.1-mini"
            )
        ]
    )

    let payload = DashboardAggregator().build(
        site: site,
        dashboardStats: dashboardStats,
        dashboardSnapshot: dashboardSnapshot,
        accounts: [],
        usages: [:]
    )

    #expect(payload.dashboardUserRanking.map(\.displayName) == ["team-b", "team-a"])
}

@Test
func aggregatorPreservesExplicitZeroValuesInsteadOfFallingBackToSnapshot() throws {
    let site = SiteConfiguration(
        name: "demo",
        baseURL: URL(string: "https://demo.example.com")!,
        adminToken: "token"
    )
    let statsJSON = """
    {
      "total_accounts": 0,
      "today_tokens": 0,
      "total_tokens": 500,
      "today_cost": 0,
      "today_actual_cost": 0,
      "total_cost": 9.4,
      "total_actual_cost": 6.2
    }
    """
    let dashboardStats = try JSONDecoder.sub2api.decode(
        AdminDashboardStatsDTO.self,
        from: Data(statsJSON.utf8)
    )
    let dashboardSnapshot = AdminDashboardSnapshotDTO(
        stats: AdminDashboardSnapshotStatsDTO(
            todayTokens: 2_200_000,
            todayStandardCost: 16.8,
            todayActualCost: 11.2
        ),
        models: [],
        usersTrend: []
    )

    let payload = DashboardAggregator().build(
        site: site,
        dashboardStats: dashboardStats,
        dashboardSnapshot: dashboardSnapshot,
        accounts: [],
        usages: [:]
    )

    #expect(payload.summary.totalAccounts == 0)
    #expect(payload.summary.todayTokens == 0)
    #expect(payload.summary.todayStandardCost == 0)
    #expect(payload.summary.todayActualCost == 0)
}

@Test
func aggregatorFallsBackToSnapshotStatsWhenDashboardStatsFieldsAreMissing() throws {
    let site = SiteConfiguration(
        name: "demo",
        baseURL: URL(string: "https://demo.example.com")!,
        adminToken: "token"
    )
    let statsJSON = """
    {
      "total_accounts": 3,
      "total_tokens": 500,
      "total_cost": 9.4,
      "total_actual_cost": 6.2
    }
    """
    let dashboardStats = try JSONDecoder.sub2api.decode(
        AdminDashboardStatsDTO.self,
        from: Data(statsJSON.utf8)
    )
    let dashboardSnapshot = AdminDashboardSnapshotDTO(
        stats: AdminDashboardSnapshotStatsDTO(
            todayTokens: 2_200_000,
            todayStandardCost: 16.8,
            todayActualCost: 11.2
        ),
        models: [],
        usersTrend: []
    )

    let payload = DashboardAggregator().build(
        site: site,
        dashboardStats: dashboardStats,
        dashboardSnapshot: dashboardSnapshot,
        accounts: [],
        usages: [:]
    )

    #expect(payload.summary.todayTokens == 2_200_000)
    #expect(payload.summary.todayStandardCost == 16.8)
    #expect(payload.summary.todayActualCost == 11.2)
    #expect(payload.summary.totalTokens == 500)
}

@Test
func dashboardUserRankingItemIDsRemainDistinctForDuplicateNames() {
    let site = SiteConfiguration(
        name: "demo",
        baseURL: URL(string: "https://demo.example.com")!,
        adminToken: "token"
    )
    let dashboardStats = AdminDashboardStatsDTO(
        totalAccounts: 0,
        todayTokens: 100,
        totalTokens: 200,
        todayStandardCost: 1.2,
        todayActualCost: 0.9,
        totalStandardCost: 4.8,
        totalActualCost: 3.6
    )
    let dashboardSnapshot = AdminDashboardSnapshotDTO(
        stats: nil,
        models: [],
        usersTrend: [
            AdminDashboardUserRankingDTO(
                name: "team-a",
                tokens: 410_000,
                actualCost: 3.1,
                standardCost: 4.0,
                primaryModel: "gpt-4.1"
            ),
            AdminDashboardUserRankingDTO(
                name: "team-a",
                tokens: 820_000,
                actualCost: 8.4,
                standardCost: 10.5,
                primaryModel: "gpt-4.1-mini"
            )
        ]
    )

    let payload = DashboardAggregator().build(
        site: site,
        dashboardStats: dashboardStats,
        dashboardSnapshot: dashboardSnapshot,
        accounts: [],
        usages: [:]
    )

    #expect(Set(payload.dashboardUserRanking.map { $0.id }).count == 2)
}
