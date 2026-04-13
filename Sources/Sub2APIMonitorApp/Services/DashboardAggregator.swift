import Foundation

struct DashboardPayload: Sendable {
    var summary: SiteSummary
    var cards: [AccountCardModel]
    var dashboardModels: [DashboardModelItem] = []
    var dashboardUserRanking: [DashboardUserRankingItem] = []
    var primaryModelName: String = "-"
}

struct DashboardAggregator {
    var referenceDate: Date = .now

    func build(
        site: SiteConfiguration,
        dashboardStats: AdminDashboardStatsDTO,
        accounts: [AdminAccountDTO],
        usages: [Int: AccountUsageInfoDTO]
    ) -> DashboardPayload {
        build(
            site: site,
            dashboardStats: dashboardStats,
            dashboardSnapshot: AdminDashboardSnapshotDTO(),
            accounts: accounts,
            usages: usages
        )
    }

    func build(
        site: SiteConfiguration,
        dashboardStats: AdminDashboardStatsDTO,
        dashboardSnapshot: AdminDashboardSnapshotDTO,
        accounts: [AdminAccountDTO],
        usages: [Int: AccountUsageInfoDTO]
    ) -> DashboardPayload {
        let cards = accounts.map { account in
            let usage = usages[account.id]
            let fiveHourProgress = preferredProgress(
                account.extra?.codex5hUsedPercent,
                resetAfterSeconds: account.extra?.codex5hResetAfterSeconds,
                resetsAt: account.extra?.codex5hResetAt,
                fallback: usage?.fiveHour
            )
            let sevenDayProgress = preferredProgress(
                account.extra?.codex7dUsedPercent,
                resetAfterSeconds: account.extra?.codex7dResetAfterSeconds,
                resetsAt: account.extra?.codex7dResetAt,
                fallback: usage?.sevenDay
            )
            let fiveHourUtilization = normalizedUtilization(fiveHourProgress?.utilization)
            let sevenDayUtilization = normalizedUtilization(sevenDayProgress?.utilization)
            let state = mapState(
                for: account,
                fiveHourUtilization: fiveHourUtilization,
                sevenDayUtilization: sevenDayUtilization
            )

            return AccountCardModel(
                id: account.id,
                name: account.name,
                state: state,
                currentConcurrency: account.currentConcurrency ?? 0,
                lastUsedAt: account.lastUsedAt,
                fiveHourUtilization: fiveHourUtilization,
                fiveHourCountdownText: countdownText(from: fiveHourProgress),
                fiveHourWindowText: windowText(title: "5h", progress: fiveHourProgress, utilization: fiveHourUtilization),
                sevenDayUtilization: sevenDayUtilization,
                sevenDayCountdownText: countdownText(from: sevenDayProgress),
                sevenDayWindowText: windowText(title: "7d", progress: sevenDayProgress, utilization: sevenDayUtilization),
                modelDisplayText: account.extra?.preferredModelDisplayText ?? "-"
            )
        }
        .sorted(by: AccountCardModel.sortForDisplay)

        let snapshotStats = dashboardSnapshot.stats
        let dashboardModels = mapDashboardModels(from: dashboardSnapshot.models)
        let dashboardUserRanking = mapDashboardUsers(from: dashboardSnapshot.usersTrend)
        let summary = SiteSummary(
            siteName: site.name,
            baseURL: site.baseURL,
            totalAccounts: dashboardStats.reportedTotalAccounts ?? accounts.count,
            todayTokens: dashboardStats.reportedTodayTokens ?? snapshotStats?.todayTokens ?? 0,
            totalTokens: dashboardStats.reportedTotalTokens ?? 0,
            todayActualCost: dashboardStats.reportedTodayActualCost ?? snapshotStats?.todayActualCost ?? 0,
            todayStandardCost: dashboardStats.reportedTodayStandardCost ?? snapshotStats?.todayStandardCost ?? 0,
            totalActualCost: dashboardStats.reportedTotalActualCost ?? 0,
            totalStandardCost: dashboardStats.reportedTotalStandardCost ?? 0,
            lastRefreshedAt: referenceDate
        )

        return DashboardPayload(
            summary: summary,
            cards: cards,
            dashboardModels: dashboardModels,
            dashboardUserRanking: dashboardUserRanking,
            primaryModelName: dashboardModels.first?.modelName ?? dashboardUserRanking.first?.primaryModel ?? "-"
        )
    }

    private func normalizedUtilization(_ rawValue: Double?) -> Double {
        guard let rawValue else {
            return 0
        }

        let normalized = rawValue > 1 ? rawValue / 100 : rawValue
        return min(max(normalized, 0), 1)
    }

    private func preferredProgress(
        _ usedPercent: Double?,
        resetAfterSeconds: Int?,
        resetsAt: Date?,
        fallback: AccountUsageProgressDTO?
    ) -> AccountUsageProgressDTO? {
        if usedPercent != nil || resetAfterSeconds != nil || resetsAt != nil {
            return AccountUsageProgressDTO(
                utilization: usedPercent ?? 0,
                resetsAt: resetsAt,
                remainingSeconds: resetAfterSeconds ?? 0
            )
        }

        return fallback
    }

    private func countdownText(from progress: AccountUsageProgressDTO?) -> String {
        guard let progress else {
            return ""
        }

        if progress.remainingSeconds > 0 {
            return CountdownFormatter.string(from: progress.remainingSeconds)
        }

        if let resetsAt = progress.resetsAt {
            return CountdownFormatter.string(until: resetsAt)
        }

        return ""
    }

    private func windowText(title: String, progress: AccountUsageProgressDTO?, utilization: Double) -> String {
        guard progress != nil else {
            return "暂无 \(title) 数据"
        }

        let usedPercentage = percentString(utilization)
        let remainingPercentage = percentString(1 - utilization)
        return "已用 \(usedPercentage) · 剩余 \(remainingPercentage)"
    }

    private func percentString(_ value: Double) -> String {
        let bounded = min(max(value, 0), 1)
        return "\(Int((bounded * 100).rounded()))%"
    }

    private func mapDashboardModels(from models: [AdminDashboardModelDTO]) -> [DashboardModelItem] {
        let totalTokens = models.reduce(0) { partialResult, model in
            partialResult + max(model.tokens, 0)
        }

        let items: [DashboardModelItem] = models.map { model in
            let ratio = model.ratio ?? fallbackModelRatio(for: model.tokens, totalTokens: totalTokens)
            return DashboardModelItem(
                modelName: model.model,
                tokenCount: model.tokens,
                actualCost: model.actualCost,
                ratio: normalizedUtilization(ratio)
            )
        }

        return items.sorted(by: { lhs, rhs in
            if lhs.ratio != rhs.ratio {
                return lhs.ratio > rhs.ratio
            }

            if lhs.actualCost != rhs.actualCost {
                return lhs.actualCost > rhs.actualCost
            }

            return lhs.modelName.localizedCaseInsensitiveCompare(rhs.modelName) == .orderedAscending
        })
    }

    private func fallbackModelRatio(for tokens: Int, totalTokens: Int) -> Double {
        guard totalTokens > 0 else {
            return 0
        }

        return Double(max(tokens, 0)) / Double(totalTokens)
    }

    private func mapDashboardUsers(from users: [AdminDashboardUserRankingDTO]) -> [DashboardUserRankingItem] {
        users
            .map { user in
                DashboardUserRankingItem(
                    displayName: user.name,
                    tokenCount: user.tokens,
                    actualCost: user.actualCost,
                    standardCost: user.standardCost,
                    primaryModel: user.primaryModel
                )
            }
            .sorted { lhs, rhs in
                if lhs.actualCost != rhs.actualCost {
                    return lhs.actualCost > rhs.actualCost
                }

                if lhs.standardCost != rhs.standardCost {
                    return lhs.standardCost > rhs.standardCost
                }

                return lhs.displayName.localizedCaseInsensitiveCompare(rhs.displayName) == .orderedAscending
            }
    }

    private func mapState(
        for account: AdminAccountDTO,
        fiveHourUtilization: Double,
        sevenDayUtilization: Double
    ) -> AccountCardState {
        if
            (account.currentConcurrency ?? 0) > 0
            || account.wasUsedRecently(within: AccountDisplayRules.recentlyUsedWindow, referenceDate: referenceDate)
        {
            return .inUse
        }

        if account.isRateLimitedNow {
            return .rateLimited
        }

        if
            account.status != "active"
            || account.schedulable == false
            || account.isTemporarilyUnschedulableNow
            || account.isOverloadedNow
        {
            return .unschedulable
        }

        if
            fiveHourUtilization >= AccountDisplayRules.highFiveHourUtilizationThreshold
            || sevenDayUtilization >= AccountDisplayRules.tightSevenDayUtilizationThreshold
        {
            return .tight
        }

        return .healthy
    }
}
