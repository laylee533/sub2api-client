import Foundation

struct AccountUsageProgressDTO: Decodable, Sendable {
    var utilization: Double
    var resetsAt: Date?
    var remainingSeconds: Int
}

struct AccountUsageInfoDTO: Decodable, Sendable {
    var updatedAt: Date?
    var fiveHour: AccountUsageProgressDTO?
    var sevenDay: AccountUsageProgressDTO?
}
