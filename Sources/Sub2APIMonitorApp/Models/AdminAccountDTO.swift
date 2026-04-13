import Foundation

struct AdminAccountExtraDTO: Decodable, Sendable {
    var codexUsageUpdatedAt: Date?
    var codex5hUsedPercent: Double?
    var codex5hResetAfterSeconds: Int?
    var codex5hResetAt: Date?
    var codex5hWindowMinutes: Int?
    var codex7dUsedPercent: Double?
    var codex7dResetAfterSeconds: Int?
    var codex7dResetAt: Date?
    var codex7dWindowMinutes: Int?
    var upstreamModel: String?
    var requestedModel: String?
    var primaryModel: String?
    var model: String?

    init(
        codexUsageUpdatedAt: Date? = nil,
        codex5hUsedPercent: Double? = nil,
        codex5hResetAfterSeconds: Int? = nil,
        codex5hResetAt: Date? = nil,
        codex5hWindowMinutes: Int? = nil,
        codex7dUsedPercent: Double? = nil,
        codex7dResetAfterSeconds: Int? = nil,
        codex7dResetAt: Date? = nil,
        codex7dWindowMinutes: Int? = nil,
        upstreamModel: String? = nil,
        requestedModel: String? = nil,
        primaryModel: String? = nil,
        model: String? = nil
    ) {
        self.codexUsageUpdatedAt = codexUsageUpdatedAt
        self.codex5hUsedPercent = codex5hUsedPercent
        self.codex5hResetAfterSeconds = codex5hResetAfterSeconds
        self.codex5hResetAt = codex5hResetAt
        self.codex5hWindowMinutes = codex5hWindowMinutes
        self.codex7dUsedPercent = codex7dUsedPercent
        self.codex7dResetAfterSeconds = codex7dResetAfterSeconds
        self.codex7dResetAt = codex7dResetAt
        self.codex7dWindowMinutes = codex7dWindowMinutes
        self.upstreamModel = upstreamModel
        self.requestedModel = requestedModel
        self.primaryModel = primaryModel
        self.model = model
    }

    var preferredModelDisplayText: String? {
        [
            upstreamModel,
            requestedModel,
            primaryModel,
            model
        ]
        .lazy
        .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
        .first(where: { !$0.isEmpty })
    }

    var hasCompleteCodexWindowSnapshot: Bool {
        codex5hUsedPercent != nil && codex7dUsedPercent != nil
    }
}

struct AdminAccountDTO: Decodable, Sendable {
    var id: Int
    var name: String
    var platform: String
    var type: String
    var currentConcurrency: Int?
    var status: String
    var schedulable: Bool
    var lastUsedAt: Date?
    var rateLimitedAt: Date?
    var rateLimitResetAt: Date?
    var overloadUntil: Date?
    var tempUnschedulableUntil: Date?
    var errorMessage: String?
    var extra: AdminAccountExtraDTO?

    var isRateLimitedNow: Bool {
        guard let rateLimitResetAt else {
            return false
        }
        return rateLimitResetAt > .now
    }

    var isTemporarilyUnschedulableNow: Bool {
        guard let tempUnschedulableUntil else {
            return false
        }
        return tempUnschedulableUntil > .now
    }

    var isOverloadedNow: Bool {
        guard let overloadUntil else {
            return false
        }
        return overloadUntil > .now
    }

    func wasUsedRecently(within timeInterval: TimeInterval, referenceDate: Date = .now) -> Bool {
        guard let lastUsedAt else {
            return false
        }
        return lastUsedAt >= referenceDate.addingTimeInterval(-timeInterval)
    }
}
