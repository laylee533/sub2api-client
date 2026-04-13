import Foundation

struct PersistedSettings: Sendable {
    var sites: [PersistedSite]
    var selectedSiteID: String?

    var siteName: String {
        sites.first?.siteName ?? ""
    }

    var baseURLString: String {
        sites.first?.baseURLString ?? ""
    }

    var adminToken: String {
        sites.first?.adminToken ?? ""
    }
}

@MainActor
enum SettingsStorage {
    private static let siteNameKey = "sub2api.monitor.siteName"
    private static let baseURLKey = "sub2api.monitor.baseURL"
    private static let adminTokenKey = "sub2api.monitor.adminToken"
    private static let sitesKey = "sub2api.monitor.sites"
    private static let selectedSiteIDKey = "sub2api.monitor.selectedSiteID"

    static func load(defaults: UserDefaults = .standard) -> PersistedSettings {
        if
            let data = defaults.data(forKey: sitesKey),
            let decodedSites = try? JSONDecoder().decode([PersistedSite].self, from: data)
        {
            let sites = sanitize(decodedSites)
            let selectedSiteID = resolveSelectedSiteID(
                requestedID: defaults.string(forKey: selectedSiteIDKey),
                sites: sites
            )
            return PersistedSettings(sites: sites, selectedSiteID: selectedSiteID)
        }

        return loadLegacy(defaults: defaults)
    }

    static func save(
        sites: [PersistedSite],
        selectedSiteID: String?,
        defaults: UserDefaults = .standard
    ) throws {
        let sanitizedSites = sanitize(sites)
        let data = try JSONEncoder().encode(sanitizedSites)
        defaults.set(data, forKey: sitesKey)

        let resolvedSelectedSiteID = resolveSelectedSiteID(
            requestedID: selectedSiteID,
            sites: sanitizedSites
        )
        if let resolvedSelectedSiteID {
            defaults.set(resolvedSelectedSiteID, forKey: selectedSiteIDKey)
        } else {
            defaults.removeObject(forKey: selectedSiteIDKey)
        }

        if let firstSite = sanitizedSites.first {
            defaults.set(firstSite.siteName, forKey: siteNameKey)
            defaults.set(firstSite.baseURLString, forKey: baseURLKey)
            defaults.set(firstSite.adminToken, forKey: adminTokenKey)
        } else {
            defaults.removeObject(forKey: siteNameKey)
            defaults.removeObject(forKey: baseURLKey)
            defaults.removeObject(forKey: adminTokenKey)
        }
    }

    static func save(
        siteName: String,
        baseURLString: String,
        adminToken: String,
        defaults: UserDefaults = .standard
    ) throws {
        let trimmedBaseURL = baseURLString.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedToken = adminToken.trimmingCharacters(in: .whitespacesAndNewlines)

        let sites: [PersistedSite]
        if trimmedBaseURL.isEmpty && trimmedToken.isEmpty {
            sites = []
        } else {
            sites = [
                PersistedSite(
                    siteName: siteName,
                    baseURLString: baseURLString,
                    adminToken: adminToken
                )
            ]
        }

        try save(
            sites: sites,
            selectedSiteID: sites.first?.id,
            defaults: defaults
        )
    }

    private static func loadLegacy(defaults: UserDefaults) -> PersistedSettings {
        let siteName = defaults.string(forKey: siteNameKey) ?? ""
        let baseURLString = defaults.string(forKey: baseURLKey) ?? ""
        let adminToken = defaults.string(forKey: adminTokenKey) ?? ""
        let trimmedBaseURL = baseURLString.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedToken = adminToken.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedBaseURL.isEmpty, !trimmedToken.isEmpty else {
            return PersistedSettings(sites: [], selectedSiteID: nil)
        }

        let site = PersistedSite(
            siteName: siteName,
            baseURLString: baseURLString,
            adminToken: adminToken
        )
        return PersistedSettings(sites: [site], selectedSiteID: site.id)
    }

    private static func sanitize(_ sites: [PersistedSite]) -> [PersistedSite] {
        sites.compactMap { site in
            let normalizedID = site.id.trimmingCharacters(in: .whitespacesAndNewlines)
            let normalizedBaseURL = site.baseURLString.trimmingCharacters(in: .whitespacesAndNewlines)
            let normalizedToken = site.adminToken.trimmingCharacters(in: .whitespacesAndNewlines)

            guard !normalizedBaseURL.isEmpty, !normalizedToken.isEmpty else {
                return nil
            }

            return PersistedSite(
                id: normalizedID.isEmpty ? UUID().uuidString : normalizedID,
                siteName: site.siteName,
                baseURLString: normalizedBaseURL,
                adminToken: normalizedToken
            )
        }
    }

    private static func resolveSelectedSiteID(requestedID: String?, sites: [PersistedSite]) -> String? {
        guard !sites.isEmpty else {
            return nil
        }

        if let requestedID, sites.contains(where: { $0.id == requestedID }) {
            return requestedID
        }

        return sites.first?.id
    }
}
