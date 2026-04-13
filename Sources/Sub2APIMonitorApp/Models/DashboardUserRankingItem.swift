import Foundation

struct DashboardUserRankingItem: Identifiable, Equatable, Sendable {
    var id: String
    var displayName: String
    var tokenCount: Int
    var actualCost: Double
    var standardCost: Double
    var primaryModel: String

    init(
        displayName: String,
        tokenCount: Int,
        actualCost: Double,
        standardCost: Double,
        primaryModel: String,
        id: String? = nil
    ) {
        self.displayName = displayName
        self.tokenCount = tokenCount
        self.actualCost = actualCost
        self.standardCost = standardCost
        self.primaryModel = primaryModel
        self.id = id ?? Self.makeID(
            displayName: displayName,
            tokenCount: tokenCount,
            actualCost: actualCost,
            standardCost: standardCost,
            primaryModel: primaryModel
        )
    }

    private static func makeID(
        displayName: String,
        tokenCount: Int,
        actualCost: Double,
        standardCost: Double,
        primaryModel: String
    ) -> String {
        "\(displayName)|\(primaryModel)|\(tokenCount)|\(actualCost)|\(standardCost)"
    }
}
