import Foundation

struct DashboardModelItem: Identifiable, Equatable, Sendable {
    var id: String { modelName }
    var modelName: String
    var tokenCount: Int
    var actualCost: Double
    var ratio: Double
}
