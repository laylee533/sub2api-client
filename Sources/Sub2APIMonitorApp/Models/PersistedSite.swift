import Foundation

struct PersistedSite: Codable, Identifiable, Equatable, Sendable {
    var id: String
    var siteName: String
    var baseURLString: String
    var adminToken: String

    init(
        id: String = UUID().uuidString,
        siteName: String,
        baseURLString: String,
        adminToken: String
    ) {
        self.id = id
        self.siteName = siteName
        self.baseURLString = baseURLString
        self.adminToken = adminToken
    }

    var trimmedSiteName: String {
        siteName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var trimmedBaseURLString: String {
        baseURLString.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var trimmedAdminToken: String {
        adminToken.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
