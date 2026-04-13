import Foundation
import Testing
@testable import Sub2APIMonitorApp

@Test
func settingsStorageDoesNotDependOnKeychainAPIs() throws {
    let packageRoot = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
    let sourceURL = packageRoot.appendingPathComponent("Sources/Sub2APIMonitorApp/Services/SettingsStorage.swift")
    let source = try String(contentsOf: sourceURL, encoding: .utf8)

    #expect(source.contains("import Security") == false)
    #expect(source.contains("SecItem") == false)
}

@Test
func settingsViewIncludesTokenGuideAndConnectionButton() throws {
    let packageRoot = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
    let settingsViewURL = packageRoot.appendingPathComponent("Sources/Sub2APIMonitorApp/UI/SettingsView.swift")
    let tokenGuideURL = packageRoot.appendingPathComponent("Sources/Sub2APIMonitorApp/UI/SettingsTokenGuide.swift")
    let settingsViewSource = try String(contentsOf: settingsViewURL, encoding: .utf8)
    let tokenGuideSource = try String(contentsOf: tokenGuideURL, encoding: .utf8)

    #expect(settingsViewSource.contains("测试连接"))
    #expect(settingsViewSource.contains("新增站点"))
    #expect(settingsViewSource.contains("删除站点"))
    #expect(tokenGuideSource.contains("不知道在哪找？点击查看获取方式"))
    #expect(tokenGuideSource.contains("localStorage.getItem('auth_token')"))
}

@Test
@MainActor
func settingsStoragePersistsTrimmedValuesInUserDefaults() throws {
    let suiteName = "SettingsStorageTests.\(UUID().uuidString)"
    guard let defaults = UserDefaults(suiteName: suiteName) else {
        Issue.record("无法创建隔离的 UserDefaults suite")
        return
    }

    defaults.removePersistentDomain(forName: suiteName)

    try SettingsStorage.save(
        siteName: " demo ",
        baseURLString: "https://demo.example.com",
        adminToken: " token-123 \n",
        defaults: defaults
    )

    let persisted = SettingsStorage.load(defaults: defaults)

    #expect(persisted.siteName == " demo ")
    #expect(persisted.baseURLString == "https://demo.example.com")
    #expect(persisted.adminToken == "token-123")
    #expect(defaults.string(forKey: "sub2api.monitor.adminToken") == "token-123")

    defaults.removePersistentDomain(forName: suiteName)
}

@Test
@MainActor
func settingsStoragePersistsMultipleSitesAndSelectedSiteID() throws {
    let suiteName = "SettingsStorageMultiSite.\(UUID().uuidString)"
    guard let defaults = UserDefaults(suiteName: suiteName) else {
        Issue.record("无法创建隔离的 UserDefaults suite")
        return
    }

    defaults.removePersistentDomain(forName: suiteName)

    let sites = [
        PersistedSite(id: "site-a", siteName: "A 站", baseURLString: "https://a.example.com", adminToken: " token-a "),
        PersistedSite(id: "site-b", siteName: "B 站", baseURLString: "https://b.example.com", adminToken: "token-b")
    ]

    try SettingsStorage.save(sites: sites, selectedSiteID: "site-b", defaults: defaults)

    let persisted = SettingsStorage.load(defaults: defaults)

    #expect(persisted.selectedSiteID == "site-b")
    #expect(persisted.sites.map(\.id) == ["site-a", "site-b"])
    #expect(persisted.sites.map(\.siteName) == ["A 站", "B 站"])
    #expect(persisted.sites.map(\.adminToken) == ["token-a", "token-b"])

    defaults.removePersistentDomain(forName: suiteName)
}

@Test
@MainActor
func settingsStorageMigratesLegacySingleSiteIntoMultiSiteCollection() throws {
    let suiteName = "SettingsStorageMigration.\(UUID().uuidString)"
    guard let defaults = UserDefaults(suiteName: suiteName) else {
        Issue.record("无法创建隔离的 UserDefaults suite")
        return
    }

    defaults.removePersistentDomain(forName: suiteName)
    defaults.set("旧站点", forKey: "sub2api.monitor.siteName")
    defaults.set("https://legacy.example.com", forKey: "sub2api.monitor.baseURL")
    defaults.set("legacy-token", forKey: "sub2api.monitor.adminToken")

    let persisted = SettingsStorage.load(defaults: defaults)

    #expect(persisted.sites.count == 1)
    #expect(persisted.sites.first?.siteName == "旧站点")
    #expect(persisted.sites.first?.baseURLString == "https://legacy.example.com")
    #expect(persisted.sites.first?.adminToken == "legacy-token")
    #expect(persisted.selectedSiteID == persisted.sites.first?.id)

    defaults.removePersistentDomain(forName: suiteName)
}
