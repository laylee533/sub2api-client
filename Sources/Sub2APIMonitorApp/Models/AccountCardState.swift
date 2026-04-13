import Foundation

enum AccountCardState: Int, Codable, Sendable {
    case inUse = 0
    case tight = 1
    case rateLimited = 2
    case unschedulable = 3
    case healthy = 4

    var badgeTitle: String {
        switch self {
        case .inUse:
            "使用中"
        case .tight:
            "紧张"
        case .rateLimited:
            "限流"
        case .unschedulable:
            "不可调度"
        case .healthy:
            "正常"
        }
    }

    var displayPriority: Int {
        switch self {
        case .inUse:
            0
        case .tight:
            1
        case .healthy:
            2
        case .rateLimited:
            3
        case .unschedulable:
            4
        }
    }

    var isAbnormal: Bool {
        switch self {
        case .rateLimited, .unschedulable:
            true
        case .inUse, .tight, .healthy:
            false
        }
    }
}
