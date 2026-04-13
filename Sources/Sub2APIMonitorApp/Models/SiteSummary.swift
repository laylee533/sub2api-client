import Foundation

struct SiteSummary: Equatable, Sendable {
    var siteName: String
    var baseURL: URL
    var totalAccounts: Int
    var todayTokens: Int
    var totalTokens: Int
    var todayActualCost: Double = 0
    var todayStandardCost: Double = 0
    var totalActualCost: Double = 0
    var totalStandardCost: Double = 0
    var lastRefreshedAt: Date

    var accountsURL: URL {
        baseURL.appending(path: "admin/accounts")
    }
}
