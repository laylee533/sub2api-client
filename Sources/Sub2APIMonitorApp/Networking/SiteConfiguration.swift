import Foundation

struct SiteConfiguration: Equatable, Sendable {
    var name: String
    var baseURL: URL
    var adminToken: String

    var accountsURL: URL {
        baseURL.appending(path: "admin/accounts")
    }

    var apiBaseURL: URL {
        baseURL.appending(path: "api/v1")
    }

    func apiURL(path: String, queryItems: [URLQueryItem] = []) -> URL? {
        let sanitizedPath = path.hasPrefix("/") ? String(path.dropFirst()) : path
        var components = URLComponents(url: apiBaseURL.appending(path: sanitizedPath), resolvingAgainstBaseURL: false)
        let mergedQueryItems = queryItems + [URLQueryItem(name: "timezone", value: TimeZone.current.identifier)]
        components?.queryItems = mergedQueryItems.isEmpty ? nil : mergedQueryItems
        return components?.url
    }
}
