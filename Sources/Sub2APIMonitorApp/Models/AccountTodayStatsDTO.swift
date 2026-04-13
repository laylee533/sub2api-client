import Foundation

struct AccountTodayStatsDTO: Decodable, Sendable {
    var requests: Int
    var totalTokens: Int
}
