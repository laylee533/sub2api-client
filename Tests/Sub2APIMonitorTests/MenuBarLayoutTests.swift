import AppKit
import SwiftUI
import Testing
@testable import Sub2APIMonitorApp

@Test
func menuBarPopupHeightClampsToStableRange() {
    #expect(MenuBarPopupLayout.preferredHeight(for: 0) == 280)
    #expect(MenuBarPopupLayout.preferredHeight(for: 180) == 280)
    #expect(MenuBarPopupLayout.preferredHeight(for: 360) == 360)
    #expect(MenuBarPopupLayout.preferredHeight(for: 900) == 540)
}

@Test
@MainActor
func menuBarRootViewHasMeaningfulFittingHeight() {
    let model = AppModel()
    model.siteNameInput = "demo"
    model.baseURLInput = "https://demo.example.com"
    model.adminTokenInput = "token"
    model.summary = MockFixtures.summary
    model.cards = Array(MockFixtures.cards.prefix(2))

    let hostingView = NSHostingView(
        rootView: MenuBarRootView(model: model)
            .frame(width: 410)
    )

    let fittingSize = hostingView.fittingSize

    #expect(fittingSize.height > 200)
}

@Test
@MainActor
func statusItemSymbolNameRemainsStableDuringConfiguredRefreshLifecycle() {
    let model = AppModel()
    model.siteNameInput = "demo"
    model.baseURLInput = "https://demo.example.com"
    model.adminTokenInput = "token"

    let initialSymbol = model.statusItemSymbolName

    model.isLoading = true
    let loadingSymbol = model.statusItemSymbolName

    model.isLoading = false
    model.cards = [MockFixtures.cards[0]]
    let loadedSymbol = model.statusItemSymbolName

    #expect(initialSymbol == loadingSymbol)
    #expect(initialSymbol == loadedSymbol)
}

@Test
func menuBarRootViewUsesCollapsedSitePickerAndRemovesLegacyTabCopy() throws {
    let packageRoot = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
    let menuBarRootViewURL = packageRoot.appendingPathComponent("Sources/Sub2APIMonitorApp/UI/MenuBarRootView.swift")
    let source = try String(contentsOf: menuBarRootViewURL, encoding: .utf8)

    #expect(source.contains("当前站点") || source.contains("站点"))
    #expect(source.contains("弹层页签") == false)
}

@Test
func dashboardTabViewNoLongerReferencesUserRankingSubtab() throws {
    let packageRoot = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
    let dashboardViewURL = packageRoot.appendingPathComponent("Sources/Sub2APIMonitorApp/UI/DashboardTabView.swift")
    let source = try String(contentsOf: dashboardViewURL, encoding: .utf8)

    #expect(source.contains("用户消费榜") == false)
}
