import Foundation

enum CountdownFormatter {
    static func string(from remainingSeconds: Int) -> String {
        guard remainingSeconds > 0 else {
            return "即将重置"
        }

        let days = remainingSeconds / 86_400
        let hours = (remainingSeconds % 86_400) / 3_600
        let minutes = (remainingSeconds % 3_600) / 60

        if days > 0 {
            return "\(days)d \(hours)h"
        }

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }

        return "\(minutes)m"
    }

    static func string(until resetAt: Date) -> String {
        string(from: max(Int(resetAt.timeIntervalSinceNow.rounded(.down)), 0))
    }
}
