import Foundation
import Observation

@MainActor
@Observable
final class AppModel {
    var summary = MockFixtures.summary
    var cards: [AccountCardModel] = []
    var selectedTab: MenuBarTab = .accounts
    var selectedDashboardSubtab: DashboardSubtab = .models
    var selectedFilter: FilterMode = .all
    var dashboardModels: [DashboardModelItem] = []
    var dashboardUserRanking: [DashboardUserRankingItem] = []
    var primaryModelName = "-"
    var isLoading = false
    var errorMessage: String?
    var settingsMessage: String?
    var connectionTestMessage: String?
    var siteNameInput = ""
    var baseURLInput = ""
    var adminTokenInput = ""
    var persistedSites: [PersistedSite] = []
    var selectedSiteID: String?
    var editingSiteID: String?
    var isSitePickerExpanded = false

    private var hasLoadedInitialData = false

    var filteredCards: [AccountCardModel] {
        let base: [AccountCardModel]

        switch selectedFilter {
        case .active:
            base = cards.filter { $0.state == .inUse }
        case .high5h:
            base = cards.filter { $0.fiveHourUtilization >= AccountDisplayRules.highFiveHourUtilizationThreshold }
        case .abnormal:
            base = cards.filter { $0.state.isAbnormal }
        case .all:
            base = cards
        }

        return base.sorted(by: AccountCardModel.sortForDisplay)
    }

    var statusItemIconMode: StatusItemIconMode {
        hasConfiguration ? .configured : .setup
    }

    var hasConfiguration: Bool {
        selectedSiteConfiguration != nil
    }

    var selectedSiteDisplayName: String {
        selectedSiteConfiguration?.name ?? "未配置站点"
    }

    var canDeleteEditingSite: Bool {
        editingSiteID != nil
    }

    var normalizedBaseURLPreview: String? {
        Self.makeBaseURL(from: baseURLInput.trimmingCharacters(in: .whitespacesAndNewlines))?.absoluteString
    }

    var dashboardEndpointPreview: String? {
        editingSiteConfiguration?.apiURL(path: "/admin/dashboard/stats")?.absoluteString
    }

    init() {
        loadSettings()
    }

    func loadIfNeeded() async {
        guard !hasLoadedInitialData else {
            await refreshIfStale()
            return
        }

        hasLoadedInitialData = true

        guard hasConfiguration else {
            errorMessage = nil
            return
        }

        await refresh()
    }

    func refreshIfStale(maxAge: TimeInterval = 60) async {
        guard hasConfiguration, !isLoading else {
            return
        }

        if summary.lastRefreshedAt.timeIntervalSinceNow >= -maxAge {
            return
        }

        await refresh()
    }

    func refresh() async {
        guard let siteConfiguration = selectedSiteConfiguration else {
            errorMessage = "请先在设置里添加站点并填写 Admin Token。"
            resetLoadedData()
            return
        }

        isLoading = true
        errorMessage = nil

        defer {
            isLoading = false
        }

        do {
            summary = SiteSummary(
                siteName: siteConfiguration.name,
                baseURL: siteConfiguration.baseURL,
                totalAccounts: 0,
                todayTokens: 0,
                totalTokens: 0,
                lastRefreshedAt: .distantPast
            )
            cards = []
            dashboardModels = []
            dashboardUserRanking = []
            primaryModelName = "-"
            connectionTestMessage = nil

            let api = AdminAccountsAPI(site: siteConfiguration)
            async let dashboardStats = api.fetchDashboardStats()
            async let dashboardSnapshot = api.fetchDashboardSnapshot()
            async let accountsTask = api.fetchAccounts()
            let accounts = try await accountsTask
            async let usages = api.fetchUsages(accounts: accounts)
            let payload = DashboardAggregator().build(
                site: siteConfiguration,
                dashboardStats: try await dashboardStats,
                dashboardSnapshot: try await dashboardSnapshot,
                accounts: accounts,
                usages: await usages
            )

            summary = payload.summary
            cards = payload.cards
            dashboardModels = payload.dashboardModels
            dashboardUserRanking = payload.dashboardUserRanking
            primaryModelName = payload.primaryModelName
            connectionTestMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func testConnection() async {
        guard let siteConfiguration = editingSiteConfiguration else {
            connectionTestMessage = "请填写有效的站点地址和 Admin Token。"
            return
        }

        isLoading = true
        connectionTestMessage = nil
        errorMessage = nil

        defer {
            isLoading = false
        }

        do {
            let stats = try await AdminAccountsAPI(site: siteConfiguration).fetchDashboardStats()
            if let totalAccounts = stats.reportedTotalAccounts {
                connectionTestMessage = "连接成功，可读取 \(totalAccounts) 个账号的统计。"
            } else {
                connectionTestMessage = "连接成功，可读取管理端统计。"
            }
        } catch {
            let message = error.localizedDescription
            errorMessage = message
            connectionTestMessage = message
        }
    }

    func saveSettings() async {
        let trimmedSiteName = siteNameInput.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedBaseURL = baseURLInput.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedToken = adminTokenInput.trimmingCharacters(in: .whitespacesAndNewlines)

        guard let siteConfiguration = editingSiteConfiguration else {
            if trimmedSiteName.isEmpty, trimmedBaseURL.isEmpty, trimmedToken.isEmpty, persistedSites.isEmpty {
                do {
                    try SettingsStorage.save(sites: [], selectedSiteID: nil)
                    applyPersistedSettings(SettingsStorage.load())
                    settingsMessage = "当前没有已保存站点。"
                } catch {
                    settingsMessage = error.localizedDescription
                }
                return
            }

            settingsMessage = "请填写有效的站点地址和 Admin Token。"
            return
        }

        let siteID = editingSiteID ?? UUID().uuidString
        let site = PersistedSite(
            id: siteID,
            siteName: trimmedSiteName.isEmpty ? siteConfiguration.name : trimmedSiteName,
            baseURLString: trimmedBaseURL,
            adminToken: trimmedToken
        )

        var updatedSites = persistedSites
        if let existingIndex = updatedSites.firstIndex(where: { $0.id == siteID }) {
            updatedSites[existingIndex] = site
        } else {
            updatedSites.append(site)
        }

        do {
            try SettingsStorage.save(sites: updatedSites, selectedSiteID: siteID)
            applyPersistedSettings(SettingsStorage.load(), preferredEditingSiteID: siteID)
            connectionTestMessage = nil
            settingsMessage = "配置已保存，正在刷新。"
            hasLoadedInitialData = true
            await refresh()
            if let errorMessage, !errorMessage.isEmpty {
                settingsMessage = errorMessage
            } else {
                settingsMessage = "配置已保存，数据已更新。"
            }
        } catch {
            settingsMessage = error.localizedDescription
        }
    }

    func selectSite(_ siteID: String) async {
        guard persistedSites.contains(where: { $0.id == siteID }) else {
            return
        }

        selectedSiteID = siteID
        editingSiteID = siteID
        loadEditorInputs(for: editingSite)
        isSitePickerExpanded = false
        errorMessage = nil
        hasLoadedInitialData = true
        await refresh()
    }

    func beginAddingSite() {
        editingSiteID = nil
        siteNameInput = ""
        baseURLInput = ""
        adminTokenInput = ""
        connectionTestMessage = nil
        settingsMessage = nil
        errorMessage = nil
    }

    func beginEditingSite(_ siteID: String) {
        guard let site = persistedSites.first(where: { $0.id == siteID }) else {
            return
        }

        editingSiteID = site.id
        loadEditorInputs(for: site)
        connectionTestMessage = nil
        settingsMessage = nil
    }

    func deleteEditingSite() async {
        guard let editingSiteID else {
            return
        }

        let remainingSites = persistedSites.filter { $0.id != editingSiteID }
        let newSelectedSiteID: String?
        if selectedSiteID == editingSiteID {
            newSelectedSiteID = remainingSites.first?.id
        } else {
            newSelectedSiteID = selectedSiteID
        }

        do {
            try SettingsStorage.save(sites: remainingSites, selectedSiteID: newSelectedSiteID)
            applyPersistedSettings(SettingsStorage.load(), preferredEditingSiteID: newSelectedSiteID)
            settingsMessage = remainingSites.isEmpty ? "站点已删除。" : "站点已删除，已切换到其他站点。"
            hasLoadedInitialData = true
            if newSelectedSiteID == nil {
                resetLoadedData()
                errorMessage = nil
            } else {
                await refresh()
            }
        } catch {
            settingsMessage = error.localizedDescription
        }
    }

    func openSiteHome() {
        guard let siteConfiguration = selectedSiteConfiguration else {
            return
        }
        BrowserNavigator.open(siteConfiguration.baseURL)
    }

    private func loadSettings() {
        applyPersistedSettings(SettingsStorage.load())

        if let siteConfiguration = selectedSiteConfiguration {
            summary = SiteSummary(
                siteName: siteConfiguration.name,
                baseURL: siteConfiguration.baseURL,
                totalAccounts: 0,
                todayTokens: 0,
                totalTokens: 0,
                lastRefreshedAt: .distantPast
            )
        }
    }

    private func applyPersistedSettings(_ settings: PersistedSettings, preferredEditingSiteID: String? = nil) {
        persistedSites = settings.sites
        selectedSiteID = settings.selectedSiteID

        let fallbackEditingSiteID = preferredEditingSiteID ?? settings.selectedSiteID ?? settings.sites.first?.id
        editingSiteID = fallbackEditingSiteID
        loadEditorInputs(for: editingSite)

        if settings.sites.isEmpty {
            errorMessage = nil
        }
    }

    private func loadEditorInputs(for site: PersistedSite?) {
        siteNameInput = site?.siteName ?? ""
        baseURLInput = site?.baseURLString ?? ""
        adminTokenInput = site?.adminToken ?? ""
    }

    private func resetLoadedData() {
        cards = []
        dashboardModels = []
        dashboardUserRanking = []
        primaryModelName = "-"
        connectionTestMessage = nil
    }

    private var selectedSite: PersistedSite? {
        if let selectedSiteID, let matchingSite = persistedSites.first(where: { $0.id == selectedSiteID }) {
            return matchingSite
        }
        return persistedSites.first
    }

    private var editingSite: PersistedSite? {
        if let editingSiteID, let matchingSite = persistedSites.first(where: { $0.id == editingSiteID }) {
            return matchingSite
        }
        return selectedSite
    }

    private var selectedSiteConfiguration: SiteConfiguration? {
        configuration(
            siteName: selectedSite?.siteName ?? "",
            baseURLString: selectedSite?.baseURLString ?? "",
            adminToken: selectedSite?.adminToken ?? ""
        )
    }

    private var editingSiteConfiguration: SiteConfiguration? {
        configuration(
            siteName: siteNameInput,
            baseURLString: baseURLInput,
            adminToken: adminTokenInput
        )
    }

    private func configuration(siteName: String, baseURLString: String, adminToken: String) -> SiteConfiguration? {
        let trimmedToken = adminToken.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedToken.isEmpty else {
            return nil
        }

        let trimmedBaseURL = baseURLString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let baseURL = Self.makeBaseURL(from: trimmedBaseURL) else {
            return nil
        }

        let trimmedSiteName = siteName.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedName = trimmedSiteName.isEmpty ? (baseURL.host ?? "sub2api") : trimmedSiteName

        return SiteConfiguration(name: resolvedName, baseURL: baseURL, adminToken: trimmedToken)
    }

    private static func makeBaseURL(from rawValue: String) -> URL? {
        guard !rawValue.isEmpty else {
            return nil
        }

        if let url = URL(string: rawValue), url.scheme != nil {
            return normalizedBaseURL(url)
        }

        return URL(string: "https://\(rawValue)").map(normalizedBaseURL)
    }

    private static func normalizedBaseURL(_ url: URL) -> URL {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return url
        }
        components.query = nil
        components.fragment = nil
        components.path = normalizedBasePath(components.path)
        return components.url ?? url
    }

    private static func normalizedBasePath(_ rawPath: String) -> String {
        let segments = rawPath
            .split(separator: "/")
            .map(String.init)

        guard !segments.isEmpty else {
            return ""
        }

        if let adminIndex = segments.firstIndex(of: "admin") {
            let kept = Array(segments[..<adminIndex])
            return kept.isEmpty ? "" : "/" + kept.joined(separator: "/")
        }

        if segments.count >= 2, Array(segments.suffix(2)) == ["api", "v1"] {
            let kept = Array(segments.dropLast(2))
            return kept.isEmpty ? "" : "/" + kept.joined(separator: "/")
        }

        return rawPath == "/" ? "" : rawPath
    }
}
