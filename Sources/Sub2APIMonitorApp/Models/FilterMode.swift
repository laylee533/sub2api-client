import Foundation

enum FilterMode: String, CaseIterable, Sendable {
    case active
    case high5h
    case abnormal
    case all

    var title: String {
        switch self {
        case .active:
            "正在使用中"
        case .high5h:
            "5h 高占用"
        case .abnormal:
            "异常"
        case .all:
            "全部"
        }
    }
}
