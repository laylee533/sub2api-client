import Foundation

struct AccountCardModel: Identifiable, Equatable, Sendable {
    var id: Int
    var name: String
    var state: AccountCardState
    var currentConcurrency: Int
    var lastUsedAt: Date?
    var fiveHourUtilization: Double
    var fiveHourCountdownText: String
    var fiveHourWindowText: String = ""
    var sevenDayUtilization: Double
    var sevenDayCountdownText: String
    var sevenDayWindowText: String = ""
    var modelDisplayText: String = "-"

    static func sortForDisplay(_ lhs: AccountCardModel, _ rhs: AccountCardModel) -> Bool {
        if lhs.state.displayPriority != rhs.state.displayPriority {
            return lhs.state.displayPriority < rhs.state.displayPriority
        }

        if lhs.lastUsedAt != rhs.lastUsedAt {
            return (lhs.lastUsedAt ?? .distantPast) > (rhs.lastUsedAt ?? .distantPast)
        }

        if lhs.fiveHourUtilization != rhs.fiveHourUtilization {
            return lhs.fiveHourUtilization > rhs.fiveHourUtilization
        }

        return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
    }
}
