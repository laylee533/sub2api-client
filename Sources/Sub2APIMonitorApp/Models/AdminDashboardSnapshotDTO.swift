import Foundation

struct AdminDashboardSnapshotDTO: Decodable, Sendable {
    var stats: AdminDashboardSnapshotStatsDTO?
    var models: [AdminDashboardModelDTO]
    var usersTrend: [AdminDashboardUserRankingDTO]

    init(
        stats: AdminDashboardSnapshotStatsDTO? = nil,
        models: [AdminDashboardModelDTO] = [],
        usersTrend: [AdminDashboardUserRankingDTO] = []
    ) {
        self.stats = stats
        self.models = models
        self.usersTrend = usersTrend
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        stats = try container.decodeIfPresent(AdminDashboardSnapshotStatsDTO.self, forKey: .stats)
        models = try container.decodeIfPresent([AdminDashboardModelDTO].self, forKey: .models) ?? []
        usersTrend = try container.decodeIfPresent([AdminDashboardUserRankingDTO].self, forKey: .usersTrend) ?? []
    }

    private enum CodingKeys: String, CodingKey {
        case stats
        case models
        case usersTrend
    }
}

struct AdminDashboardSnapshotStatsDTO: Decodable, Sendable {
    var todayTokens: Int?
    var todayActualCost: Double?
    var todayStandardCost: Double?

    init(todayTokens: Int? = nil, todayStandardCost: Double? = nil, todayActualCost: Double? = nil) {
        self.todayTokens = todayTokens
        self.todayActualCost = todayActualCost
        self.todayStandardCost = todayStandardCost
    }

    init(todayTokens: Int? = nil, todayCost: Double? = nil, todayActualCost: Double? = nil) {
        self.init(
            todayTokens: todayTokens,
            todayStandardCost: todayCost,
            todayActualCost: todayActualCost
        )
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        todayTokens = try container.decodeIfPresent(Int.self, forKey: .todayTokens)
        todayActualCost = try container.decodeIfPresent(Double.self, forKey: .todayActualCost)
        todayStandardCost = try container.decodeIfPresent(Double.self, forKey: .todayStandardCost)
            ?? (try container.decodeIfPresent(Double.self, forKey: .todayCost))
    }

    private enum CodingKeys: String, CodingKey {
        case todayTokens
        case todayActualCost
        case todayStandardCost
        case todayCost
    }
}

struct AdminDashboardModelDTO: Decodable, Sendable {
    var model: String
    var tokens: Int
    var actualCost: Double
    var ratio: Double?

    init(model: String, tokens: Int, actualCost: Double, ratio: Double? = nil) {
        self.model = model
        self.tokens = tokens
        self.actualCost = actualCost
        self.ratio = ratio
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        model = try container.decode(String.self, forKey: .model)
        tokens = try container.decodeIfPresent(Int.self, forKey: .tokens)
            ?? (try container.decodeIfPresent(Int.self, forKey: .totalTokens))
            ?? 0
        actualCost = try container.decodeIfPresent(Double.self, forKey: .actualCost)
            ?? 0
        ratio = try container.decodeIfPresent(Double.self, forKey: .ratio)
    }

    private enum CodingKeys: String, CodingKey {
        case model
        case tokens
        case totalTokens
        case actualCost
        case ratio
    }
}

struct AdminDashboardUserRankingDTO: Decodable, Sendable {
    var name: String
    var tokens: Int
    var actualCost: Double
    var standardCost: Double
    var primaryModel: String

    init(
        name: String,
        tokens: Int,
        actualCost: Double,
        standardCost: Double,
        primaryModel: String
    ) {
        self.name = name
        self.tokens = tokens
        self.actualCost = actualCost
        self.standardCost = standardCost
        self.primaryModel = primaryModel
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decodeIfPresent(String.self, forKey: .name)
            ?? (try container.decodeIfPresent(String.self, forKey: .username))
            ?? (try container.decodeIfPresent(String.self, forKey: .email))
            ?? "-"
        tokens = try container.decodeIfPresent(Int.self, forKey: .tokens) ?? 0
        actualCost = try container.decodeIfPresent(Double.self, forKey: .actualCost) ?? 0
        standardCost = try container.decodeIfPresent(Double.self, forKey: .standardCost)
            ?? (try container.decodeIfPresent(Double.self, forKey: .cost))
            ?? actualCost
        primaryModel = try container.decodeIfPresent(String.self, forKey: .primaryModel) ?? "-"
    }

    private enum CodingKeys: String, CodingKey {
        case name
        case username
        case email
        case tokens
        case actualCost
        case standardCost
        case cost
        case primaryModel
    }
}
