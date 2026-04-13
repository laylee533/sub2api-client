import Foundation
import Testing
@testable import Sub2APIMonitorApp

@Test
func apiClientDecodesDashboardStatsFromStandardEnvelope() async throws {
    let site = SiteConfiguration(
        name: "wrapped",
        baseURL: URL(string: "https://wrapped.example.com")!,
        adminToken: "token"
    )
    let client = APIClient(session: await makeMockSession(statusCode: 200, body: """
    {
      "code": 0,
      "message": "success",
      "data": {
        "total_accounts": 12,
        "today_tokens": 3456,
        "total_tokens": 7890
      }
    }
    """, site: site, path: "/admin/dashboard/stats"))

    let stats = try await client.get(AdminDashboardStatsDTO.self, site: site, path: "/admin/dashboard/stats")

    #expect(stats.totalAccounts == 12)
    #expect(stats.todayTokens == 3456)
    #expect(stats.totalTokens == 7890)
}

@Test
func apiClientDecodesDashboardStatsFromRawJSONPayload() async throws {
    let site = SiteConfiguration(
        name: "raw",
        baseURL: URL(string: "https://raw.example.com")!,
        adminToken: "token"
    )
    let client = APIClient(session: await makeMockSession(statusCode: 200, body: """
    {
      "total_accounts": 12,
      "today_tokens": 3456,
      "total_tokens": 7890
    }
    """, site: site, path: "/admin/dashboard/stats"))

    let stats = try await client.get(AdminDashboardStatsDTO.self, site: site, path: "/admin/dashboard/stats")

    #expect(stats.totalAccounts == 12)
    #expect(stats.todayTokens == 3456)
    #expect(stats.totalTokens == 7890)
}

@Test
func apiClientReportsMissingDataFieldForSuccessfulEnvelopeWithoutPayload() async throws {
    let site = SiteConfiguration(
        name: "missing-data",
        baseURL: URL(string: "https://missing-data.example.com")!,
        adminToken: "token"
    )
    let client = APIClient(session: await makeMockSession(statusCode: 200, body: """
    {
      "code": 0,
      "message": "success"
    }
    """, site: site, path: "/admin/dashboard/stats"))

    do {
        _ = try await client.get(AdminDashboardStatsDTO.self, site: site, path: "/admin/dashboard/stats")
        Issue.record("Expected missingResponseData error")
    } catch APIClientError.missingResponseData {
        #expect(Bool(true))
    } catch {
        Issue.record("Unexpected error: \(error)")
    }
}

@Test
func apiClientPreservesDecodingErrorWhenEnvelopeHasDataButPayloadShapeIsWrong() async throws {
    let site = SiteConfiguration(
        name: "bad-payload",
        baseURL: URL(string: "https://bad-payload.example.com")!,
        adminToken: "token"
    )
    let client = APIClient(session: await makeMockSession(statusCode: 200, body: """
    {
      "code": 0,
      "message": "success",
      "data": {
        "stats": {
          "today_tokens": "oops"
        }
      }
    }
    """, site: site, path: "/admin/dashboard/snapshot-v2"))

    do {
        _ = try await client.get(AdminDashboardSnapshotDTO.self, site: site, path: "/admin/dashboard/snapshot-v2")
        Issue.record("Expected decoding error")
    } catch let error as DecodingError {
        switch error {
        case let .keyNotFound(key, _):
            Issue.record("Unexpected keyNotFound: \(key.stringValue)")
        case let .typeMismatch(type, _):
            #expect(String(describing: type) == "Int")
        default:
            Issue.record("Unexpected decoding error: \(error)")
        }
    } catch {
        Issue.record("Unexpected error: \(error)")
    }
}

private func makeMockSession(statusCode: Int, body: String, site: SiteConfiguration, path: String) async -> URLSession {
    let payload = Data(body.utf8)
    let requestURL = try! #require(site.apiURL(path: path))
    await MockResponseStore.shared.setResponse(for: requestURL, statusCode: statusCode, payload: payload)

    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [MockURLProtocol.self]
    return URLSession(configuration: configuration)
}

private final class MockURLProtocol: URLProtocol, @unchecked Sendable {
    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        Task {
            do {
                let (response, data) = try await MockResponseStore.shared.response(for: request)
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                client?.urlProtocol(self, didLoad: data)
                client?.urlProtocolDidFinishLoading(self)
            } catch {
                client?.urlProtocol(self, didFailWithError: error)
            }
        }
    }

    override func stopLoading() {}
}

private actor MockResponseStore {
    static let shared = MockResponseStore()

    private var responses: [URL: (Int, Data)] = [:]

    func setResponse(for url: URL, statusCode: Int, payload: Data) {
        responses[url] = (statusCode, payload)
    }

    func response(for request: URLRequest) throws -> (HTTPURLResponse, Data) {
        let url = try #require(request.url)
        let (statusCode, payload) = try #require(responses[url])
        let response = HTTPURLResponse(
            url: url,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        )!
        return (response, payload)
    }
}
