import Foundation
import Testing
@testable import Sub2APIMonitorApp

@Test
func dashboardSnapshotDecodesModelsAndUsersRanking() throws {
    struct Envelope<T: Decodable>: Decodable {
        let code: Int
        let message: String
        let data: T
    }

    let json = """
    {
      "code": 0,
      "message": "ok",
      "data": {
        "stats": {
          "today_tokens": 2200000,
          "today_cost": 16.8,
          "today_actual_cost": 11.2
        },
        "models": [
          { "model": "gpt-4.1-mini", "tokens": 1200000, "actual_cost": 4.2, "ratio": 0.54 }
        ],
        "users_trend": [
          { "name": "team-a", "tokens": 540000, "actual_cost": 2.9, "standard_cost": 4.0, "primary_model": "gpt-4.1-mini" }
        ]
      }
    }
    """

    let envelope = try JSONDecoder.sub2api.decode(
        Envelope<AdminDashboardSnapshotDTO>.self,
        from: Data(json.utf8)
    )

    #expect(envelope.data.stats?.todayTokens == 2_200_000)
    #expect(envelope.data.stats?.todayStandardCost == 16.8)
    #expect(envelope.data.models.first?.model == "gpt-4.1-mini")
    #expect(envelope.data.usersTrend.first?.primaryModel == "gpt-4.1-mini")
}

@Test
func dashboardSnapshotDecodesUpstreamSnapshotV2ModelShape() throws {
    struct Envelope<T: Decodable>: Decodable {
        let code: Int
        let message: String
        let data: T
    }

    let json = """
    {
      "code": 0,
      "message": "success",
      "data": {
        "models": [
          {
            "model": "gpt-5.4",
            "requests": 2508,
            "input_tokens": 40921094,
            "output_tokens": 1925121,
            "cache_creation_tokens": 0,
            "cache_read_tokens": 240577024,
            "total_tokens": 283423239,
            "cost": 191.323806,
            "actual_cost": 191.323806
          }
        ]
      }
    }
    """

    let envelope = try JSONDecoder.sub2api.decode(
        Envelope<AdminDashboardSnapshotDTO>.self,
        from: Data(json.utf8)
    )

    #expect(envelope.data.models.first?.model == "gpt-5.4")
    #expect(envelope.data.models.first?.tokens == 283_423_239)
    #expect(envelope.data.models.first?.actualCost == 191.323806)
}

@Test
func dashboardSnapshotTreatsMissingArraysAsEmpty() throws {
    struct Envelope<T: Decodable>: Decodable {
        let code: Int
        let message: String
        let data: T
    }

    let json = """
    {
      "code": 0,
      "message": "ok",
      "data": {
        "stats": {
          "today_tokens": 2200000
        }
      }
    }
    """

    let envelope = try JSONDecoder.sub2api.decode(
        Envelope<AdminDashboardSnapshotDTO>.self,
        from: Data(json.utf8)
    )

    #expect(envelope.data.models.isEmpty)
    #expect(envelope.data.usersTrend.isEmpty)
}

@Test
func dashboardSnapshotTreatsNullArraysAsEmpty() throws {
    struct Envelope<T: Decodable>: Decodable {
        let code: Int
        let message: String
        let data: T
    }

    let json = """
    {
      "code": 0,
      "message": "ok",
      "data": {
        "models": null,
        "users_trend": null
      }
    }
    """

    let envelope = try JSONDecoder.sub2api.decode(
        Envelope<AdminDashboardSnapshotDTO>.self,
        from: Data(json.utf8)
    )

    #expect(envelope.data.models.isEmpty)
    #expect(envelope.data.usersTrend.isEmpty)
}
