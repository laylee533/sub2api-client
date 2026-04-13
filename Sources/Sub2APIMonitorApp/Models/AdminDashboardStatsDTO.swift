import Foundation

struct AdminDashboardStatsDTO: Decodable, Sendable {
    var reportedTotalAccounts: Int?
    var reportedTodayTokens: Int?
    var reportedTotalTokens: Int?
    var reportedTodayActualCost: Double?
    var reportedTodayStandardCost: Double?
    var reportedTotalActualCost: Double?
    var reportedTotalStandardCost: Double?

    var totalAccounts: Int { reportedTotalAccounts ?? 0 }
    var todayTokens: Int { reportedTodayTokens ?? 0 }
    var totalTokens: Int { reportedTotalTokens ?? 0 }
    var todayActualCost: Double { reportedTodayActualCost ?? 0 }
    var todayStandardCost: Double { reportedTodayStandardCost ?? 0 }
    var totalActualCost: Double { reportedTotalActualCost ?? 0 }
    var totalStandardCost: Double { reportedTotalStandardCost ?? 0 }

    init(
        totalAccounts: Int,
        todayTokens: Int,
        totalTokens: Int,
        todayStandardCost: Double = 0,
        todayActualCost: Double = 0,
        totalStandardCost: Double = 0,
        totalActualCost: Double = 0
    ) {
        reportedTotalAccounts = totalAccounts
        reportedTodayTokens = todayTokens
        reportedTotalTokens = totalTokens
        reportedTodayActualCost = todayActualCost
        reportedTodayStandardCost = todayStandardCost
        reportedTotalActualCost = totalActualCost
        reportedTotalStandardCost = totalStandardCost
    }

    init(
        totalAccounts: Int,
        todayTokens: Int,
        totalTokens: Int,
        todayCost: Double = 0,
        todayActualCost: Double = 0,
        totalCost: Double = 0,
        totalActualCost: Double = 0
    ) {
        self.init(
            totalAccounts: totalAccounts,
            todayTokens: todayTokens,
            totalTokens: totalTokens,
            todayStandardCost: todayCost,
            todayActualCost: todayActualCost,
            totalStandardCost: totalCost,
            totalActualCost: totalActualCost
        )
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        reportedTotalAccounts = try container.decodeIfPresent(Int.self, forKey: .totalAccounts)
        reportedTodayTokens = try container.decodeIfPresent(Int.self, forKey: .todayTokens)
        reportedTotalTokens = try container.decodeIfPresent(Int.self, forKey: .totalTokens)
        reportedTodayActualCost = try container.decodeIfPresent(Double.self, forKey: .todayActualCost)
        reportedTodayStandardCost = try container.decodeIfPresent(Double.self, forKey: .todayStandardCost)
            ?? (try container.decodeIfPresent(Double.self, forKey: .todayCost))
        reportedTotalActualCost = try container.decodeIfPresent(Double.self, forKey: .totalActualCost)
        reportedTotalStandardCost = try container.decodeIfPresent(Double.self, forKey: .totalStandardCost)
            ?? (try container.decodeIfPresent(Double.self, forKey: .totalCost))
    }

    private enum CodingKeys: String, CodingKey {
        case totalAccounts
        case todayTokens
        case totalTokens
        case todayActualCost
        case todayStandardCost
        case totalActualCost
        case totalStandardCost
        case todayCost
        case totalCost
    }
}
