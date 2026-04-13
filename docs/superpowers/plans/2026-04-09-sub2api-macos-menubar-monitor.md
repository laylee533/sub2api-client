# Sub2API macOS Menu Bar Monitor Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Finish the approved macOS menu bar monitor by adding the final narrow-popup account monitor, a native dashboard tab, and a flat settings window with token guidance and connection testing.

**Architecture:** Keep `AppModel` as the single observable state owner, extend the networking layer to fetch richer dashboard payloads from `sub2api`, map raw responses into compact popup-friendly view models, and split the UI into focused SwiftUI subviews for account monitoring, dashboard presentation, and settings. Preserve the existing “active first” account ordering, no-Keychain storage, and browser handoff for deep inspection.

**Tech Stack:** Swift 6, SwiftUI, Observation, Foundation, AppKit, URLSession, async/await, Swift Testing

---

## Current Baseline

- The SwiftPM macOS app already exists and builds.
- `swift build` and `swift test` were previously passing in this workspace.
- Current code already has:
  - menu bar app shell
  - account fetching
  - per-account `5h / 7d` usage fetching
  - settings storage without Keychain
  - basic summary cards
  - account sorting and layout tests
- The remaining work is a **delta plan** from the current codebase, not a greenfield scaffold.

## Upstream Data Sources To Reuse

- `GET /api/v1/admin/dashboard/stats`
  - already used by `AdminAccountsAPI.fetchDashboardStats()`
  - extend decoding to include token and cost fields needed by the popup summary
- `GET /api/v1/admin/dashboard/snapshot-v2`
  - use for native dashboard tab content
  - decode the sections needed for stats, model distribution, and user ranking
- `GET /api/v1/admin/accounts`
  - keep as the source for account list, state, and recent usage metadata
- `GET /api/v1/admin/accounts/:id/usage?source=active`
  - keep as the source for `5h / 7d` utilization windows

## Planned File Structure

- Create: `Sources/Sub2APIMonitorApp/Models/AdminDashboardSnapshotDTO.swift`
- Create: `Sources/Sub2APIMonitorApp/Models/DashboardModelItem.swift`
- Create: `Sources/Sub2APIMonitorApp/Models/DashboardUserRankingItem.swift`
- Create: `Sources/Sub2APIMonitorApp/Models/MenuBarTab.swift`
- Create: `Sources/Sub2APIMonitorApp/Models/DashboardSubtab.swift`
- Create: `Sources/Sub2APIMonitorApp/UI/AccountMonitorTabView.swift`
- Create: `Sources/Sub2APIMonitorApp/UI/DashboardTabView.swift`
- Create: `Sources/Sub2APIMonitorApp/UI/DashboardSummaryStrip.swift`
- Create: `Sources/Sub2APIMonitorApp/UI/DashboardModelList.swift`
- Create: `Sources/Sub2APIMonitorApp/UI/DashboardUserRankingList.swift`
- Create: `Sources/Sub2APIMonitorApp/UI/SettingsTokenGuide.swift`
- Create: `Tests/Sub2APIMonitorTests/DashboardSnapshotDecodingTests.swift`
- Modify: `Sources/Sub2APIMonitorApp/App/AppModel.swift`
- Modify: `Sources/Sub2APIMonitorApp/Models/AdminDashboardStatsDTO.swift`
- Modify: `Sources/Sub2APIMonitorApp/Models/AccountCardModel.swift`
- Modify: `Sources/Sub2APIMonitorApp/Models/AccountUsageInfoDTO.swift`
- Modify: `Sources/Sub2APIMonitorApp/Models/SiteSummary.swift`
- Modify: `Sources/Sub2APIMonitorApp/Networking/AdminAccountsAPI.swift`
- Modify: `Sources/Sub2APIMonitorApp/Preview/MockFixtures.swift`
- Modify: `Sources/Sub2APIMonitorApp/Services/DashboardAggregator.swift`
- Modify: `Sources/Sub2APIMonitorApp/UI/AccountCardGrid.swift`
- Modify: `Sources/Sub2APIMonitorApp/UI/AccountCardView.swift`
- Modify: `Sources/Sub2APIMonitorApp/UI/FilterChipRow.swift`
- Modify: `Sources/Sub2APIMonitorApp/UI/MenuBarPopupLayout.swift`
- Modify: `Sources/Sub2APIMonitorApp/UI/MenuBarRootView.swift`
- Modify: `Sources/Sub2APIMonitorApp/UI/ProgressStripe.swift`
- Modify: `Sources/Sub2APIMonitorApp/UI/SettingsView.swift`
- Modify: `Sources/Sub2APIMonitorApp/UI/SiteSummarySection.swift`
- Modify: `Tests/Sub2APIMonitorTests/AppModelFilterTests.swift`
- Modify: `Tests/Sub2APIMonitorTests/DashboardAggregatorTests.swift`
- Modify: `Tests/Sub2APIMonitorTests/MenuBarLayoutTests.swift`
- Modify: `Tests/Sub2APIMonitorTests/SettingsStorageSecurityTests.swift`

### Task 1: Extend Dashboard And Account View Models

**Files:**
- Create: `Sources/Sub2APIMonitorApp/Models/AdminDashboardSnapshotDTO.swift`
- Create: `Sources/Sub2APIMonitorApp/Models/DashboardModelItem.swift`
- Create: `Sources/Sub2APIMonitorApp/Models/DashboardUserRankingItem.swift`
- Modify: `Sources/Sub2APIMonitorApp/Models/AdminDashboardStatsDTO.swift`
- Modify: `Sources/Sub2APIMonitorApp/Models/AccountCardModel.swift`
- Modify: `Sources/Sub2APIMonitorApp/Models/AccountUsageInfoDTO.swift`
- Modify: `Sources/Sub2APIMonitorApp/Models/SiteSummary.swift`
- Modify: `Sources/Sub2APIMonitorApp/Services/DashboardAggregator.swift`
- Modify: `Tests/Sub2APIMonitorTests/DashboardAggregatorTests.swift`
- Create: `Tests/Sub2APIMonitorTests/DashboardSnapshotDecodingTests.swift`

- [ ] **Step 1: Write the failing aggregation and decoding tests**

```swift
import Foundation
import Testing
@testable import Sub2APIMonitorApp

@Test
func aggregatorCarriesTokenAndCostSummaryIntoSiteSummary() {
    let site = SiteConfiguration(
        name: "demo",
        baseURL: URL(string: "https://demo.example.com")!,
        adminToken: "token"
    )
    let dashboardStats = AdminDashboardStatsDTO(
        totalAccounts: 1,
        todayTokens: 1_920_000,
        totalTokens: 88_000_000,
        todayCost: 18.20,
        todayActualCost: 12.54,
        totalCost: 566.30,
        totalActualCost: 410.75
    )
    let dashboardSnapshot = AdminDashboardSnapshotDTO(
        stats: nil,
        models: [],
        usersTrend: []
    )
    let accounts = [
        AdminAccountDTO(
            id: 1,
            name: "team-1",
            platform: "openai",
            type: "oauth",
            currentConcurrency: 1,
            status: "active",
            schedulable: true,
            lastUsedAt: .now,
            rateLimitedAt: nil,
            rateLimitResetAt: nil,
            overloadUntil: nil,
            tempUnschedulableUntil: nil,
            errorMessage: nil
        )
    ]
    let usages = [
        1: AccountUsageInfoDTO(
            updatedAt: .now,
            fiveHour: AccountUsageProgressDTO(utilization: 62, resetsAt: nil, remainingSeconds: 11_400),
            sevenDay: AccountUsageProgressDTO(utilization: 71, resetsAt: nil, remainingSeconds: 143_000)
        )
    ]

    let payload = DashboardAggregator().build(
        site: site,
        dashboardStats: dashboardStats,
        dashboardSnapshot: dashboardSnapshot,
        accounts: accounts,
        usages: usages
    )

    #expect(payload.summary.todayTokens == 1_920_000)
    #expect(payload.summary.todayActualCost == 12.54)
    #expect(payload.summary.totalStandardCost == 566.30)
}

@Test
func aggregatorBuildsCompactWindowTextsForBothUsageWindows() {
    let site = SiteConfiguration(
        name: "demo",
        baseURL: URL(string: "https://demo.example.com")!,
        adminToken: "token"
    )
    let dashboardStats = AdminDashboardStatsDTO(
        totalAccounts: 1,
        todayTokens: 200,
        totalTokens: 400,
        todayCost: 1.2,
        todayActualCost: 0.8,
        totalCost: 9.4,
        totalActualCost: 6.2
    )
    let dashboardSnapshot = AdminDashboardSnapshotDTO(
        stats: nil,
        models: [],
        usersTrend: []
    )
    let accounts = [
        AdminAccountDTO(
            id: 2,
            name: "team-2",
            platform: "openai",
            type: "oauth",
            currentConcurrency: 0,
            status: "active",
            schedulable: true,
            lastUsedAt: .now.addingTimeInterval(-3_600),
            rateLimitedAt: nil,
            rateLimitResetAt: nil,
            overloadUntil: nil,
            tempUnschedulableUntil: nil,
            errorMessage: nil
        )
    ]
    let usages = [
        2: AccountUsageInfoDTO(
            updatedAt: .now,
            fiveHour: AccountUsageProgressDTO(utilization: 83, resetsAt: nil, remainingSeconds: 1_800),
            sevenDay: AccountUsageProgressDTO(utilization: 46, resetsAt: nil, remainingSeconds: 300_000)
        )
    ]

    let payload = DashboardAggregator().build(
        site: site,
        dashboardStats: dashboardStats,
        dashboardSnapshot: dashboardSnapshot,
        accounts: accounts,
        usages: usages
    )

    #expect(payload.cards[0].fiveHourWindowText.contains("已用 83%"))
    #expect(payload.cards[0].sevenDayWindowText.contains("剩余 54%"))
}

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

    let envelope = try JSONDecoder.sub2api.decode(Envelope<AdminDashboardSnapshotDTO>.self, from: Data(json.utf8))
    #expect(envelope.data.models.first?.model == "gpt-4.1-mini")
    #expect(envelope.data.usersTrend.first?.primaryModel == "gpt-4.1-mini")
}
```

- [ ] **Step 2: Run targeted tests and confirm they fail before implementation**

Run: `swift test --filter DashboardAggregatorTests`

Expected: FAIL because `SiteSummary`, `AccountCardModel`, and dashboard DTOs do not yet expose cost and dashboard-tab fields.

- [ ] **Step 3: Implement richer summary, window text, and dashboard DTOs**

```swift
struct AdminDashboardStatsDTO: Decodable, Sendable {
    var totalAccounts: Int
    var todayTokens: Int
    var totalTokens: Int
    var todayCost: Double
    var todayActualCost: Double
    var totalCost: Double
    var totalActualCost: Double
}

struct AdminDashboardSnapshotDTO: Decodable, Sendable {
    var stats: AdminDashboardSnapshotStatsDTO?
    var models: [AdminDashboardModelDTO]
    var usersTrend: [AdminDashboardUserRankingDTO]
}

struct AdminDashboardSnapshotStatsDTO: Decodable, Sendable {
    var todayTokens: Int?
    var todayCost: Double?
    var todayActualCost: Double?
}

struct AdminDashboardModelDTO: Decodable, Sendable {
    var model: String
    var tokens: Int
    var actualCost: Double
    var ratio: Double
}

struct AdminDashboardUserRankingDTO: Decodable, Sendable {
    var name: String
    var tokens: Int
    var actualCost: Double
    var standardCost: Double
    var primaryModel: String
}

struct SiteSummary: Equatable, Sendable {
    var siteName: String
    var baseURL: URL
    var totalAccounts: Int
    var todayTokens: Int
    var totalTokens: Int
    var todayActualCost: Double
    var todayStandardCost: Double
    var totalActualCost: Double
    var totalStandardCost: Double
    var lastRefreshedAt: Date
}

struct AccountCardModel: Identifiable, Equatable, Sendable {
    var id: Int
    var name: String
    var state: AccountCardState
    var currentConcurrency: Int
    var lastUsedAt: Date?
    var fiveHourUtilization: Double
    var fiveHourCountdownText: String
    var fiveHourWindowText: String
    var sevenDayUtilization: Double
    var sevenDayCountdownText: String
    var sevenDayWindowText: String
}

struct DashboardModelItem: Identifiable, Equatable, Sendable {
    var id: String { modelName }
    var modelName: String
    var tokenCount: Int
    var actualCost: Double
    var ratio: Double
}

struct DashboardUserRankingItem: Identifiable, Equatable, Sendable {
    var id: String { displayName }
    var displayName: String
    var tokenCount: Int
    var actualCost: Double
    var standardCost: Double
    var primaryModel: String
}

struct DashboardPayload: Sendable {
    var summary: SiteSummary
    var cards: [AccountCardModel]
    var dashboardModels: [DashboardModelItem]
    var dashboardUserRanking: [DashboardUserRankingItem]
    var primaryModelName: String
}
```

Implementation notes:

- Build `DashboardPayload` with:
  - `summary`
  - `cards`
  - `dashboardModels`
  - `dashboardUserRanking`
  - `primaryModelName`
- Add helper methods in `DashboardAggregator`:
  - `windowText(title:utilization:)`
  - `mapDashboardModels(from:)`
  - `mapDashboardUsers(from:)`
- Keep existing sort priority unchanged:
  - `inUse`
  - `tight`
  - `healthy`
  - `rateLimited`
  - `unschedulable`

- [ ] **Step 4: Re-run the new tests**

Run: `swift test --filter DashboardAggregatorTests`

Expected: PASS with the new summary cost fields and compact window text assertions.

Run: `swift test --filter DashboardSnapshotDecodingTests`

Expected: PASS with decoded `models` and `usersTrend`.

- [ ] **Step 5: Commit**

```bash
git add Sources/Sub2APIMonitorApp/Models Sources/Sub2APIMonitorApp/Services/DashboardAggregator.swift Tests/Sub2APIMonitorTests/DashboardAggregatorTests.swift Tests/Sub2APIMonitorTests/DashboardSnapshotDecodingTests.swift
git commit -m "feat(data): 扩展仪表盘与账号展示模型"
```

### Task 2: Update The Networking Layer And App State

**Files:**
- Create: `Sources/Sub2APIMonitorApp/Models/MenuBarTab.swift`
- Create: `Sources/Sub2APIMonitorApp/Models/DashboardSubtab.swift`
- Modify: `Sources/Sub2APIMonitorApp/App/AppModel.swift`
- Modify: `Sources/Sub2APIMonitorApp/Networking/AdminAccountsAPI.swift`
- Modify: `Sources/Sub2APIMonitorApp/Preview/MockFixtures.swift`
- Modify: `Tests/Sub2APIMonitorTests/AppModelFilterTests.swift`

- [ ] **Step 1: Write failing tests for new app state and filters**

```swift
import Testing
@testable import Sub2APIMonitorApp

@Test
@MainActor
func appModelDefaultsToAccountMonitorTabAndAllFilter() {
    let model = AppModel()
    #expect(model.selectedTab == .accounts)
    #expect(model.selectedDashboardSubtab == .models)
    #expect(model.selectedFilter == .all)
}

@Test
@MainActor
func abnormalFilterOnlyReturnsRateLimitedAndUnschedulableCards() {
    let model = AppModel()
    model.cards = [
        AccountCardModel(
            id: 1,
            name: "active",
            state: .inUse,
            currentConcurrency: 1,
            lastUsedAt: .now,
            fiveHourUtilization: 0.2,
            fiveHourCountdownText: "4h 10m",
            fiveHourWindowText: "已用 20% · 剩余 80%",
            sevenDayUtilization: 0.3,
            sevenDayCountdownText: "3d 2h",
            sevenDayWindowText: "已用 30% · 剩余 70%"
        ),
        AccountCardModel(
            id: 2,
            name: "limited",
            state: .rateLimited,
            currentConcurrency: 0,
            lastUsedAt: nil,
            fiveHourUtilization: 1.0,
            fiveHourCountdownText: "25m",
            fiveHourWindowText: "已用 100% · 剩余 0%",
            sevenDayUtilization: 0.4,
            sevenDayCountdownText: "2d 5h",
            sevenDayWindowText: "已用 40% · 剩余 60%"
        ),
        AccountCardModel(
            id: 3,
            name: "down",
            state: .unschedulable,
            currentConcurrency: 0,
            lastUsedAt: nil,
            fiveHourUtilization: 0.0,
            fiveHourCountdownText: "",
            fiveHourWindowText: "暂无窗口数据",
            sevenDayUtilization: 0.0,
            sevenDayCountdownText: "",
            sevenDayWindowText: "暂无窗口数据"
        )
    ]
    model.selectedFilter = .abnormal

    #expect(model.filteredCards.map(\.name) == ["limited", "down"])
}
```

- [ ] **Step 2: Run targeted app-model tests before changing code**

Run: `swift test --filter AppModelFilterTests`

Expected: FAIL because `selectedTab`, `selectedDashboardSubtab`, and dashboard arrays are not in `AppModel` yet.

- [ ] **Step 3: Extend `AdminAccountsAPI` and `AppModel` to own the final popup state**

```swift
enum MenuBarTab: String, CaseIterable, Sendable {
    case accounts
    case dashboard
}

enum DashboardSubtab: String, CaseIterable, Sendable {
    case models
    case users
}

@MainActor
@Observable
final class AppModel {
    var selectedTab: MenuBarTab = .accounts
    var selectedDashboardSubtab: DashboardSubtab = .models
    var dashboardModels: [DashboardModelItem] = []
    var dashboardUserRanking: [DashboardUserRankingItem] = []
    var primaryModelName = "-"
    var connectionTestMessage: String?
}

extension AdminAccountsAPI {
    func fetchDashboardSnapshot() async throws -> AdminDashboardSnapshotDTO {
        try await client.get(
            AdminDashboardSnapshotDTO.self,
            site: site,
            path: "/admin/dashboard/snapshot-v2"
        )
    }
}
```

Implementation notes:

- Update `AppModel.refresh()` to fetch concurrently:
  - `dashboardStats`
  - `dashboardSnapshot`
  - `accounts`
  - `usages`
- Remove `openAccountsPage()` from the root flow; keep only `openSiteHome()`.
- Keep `loadIfNeeded()` and `refreshIfStale()` behavior unchanged.
- Update `MockFixtures` so previews include:
  - token and cost summary values
  - compact window text
  - sample dashboard models
  - sample user ranking

- [ ] **Step 4: Re-run the app-model tests**

Run: `swift test --filter AppModelFilterTests`

Expected: PASS with the new tab state and filter assertions.

- [ ] **Step 5: Commit**

```bash
git add Sources/Sub2APIMonitorApp/App/AppModel.swift Sources/Sub2APIMonitorApp/Networking/AdminAccountsAPI.swift Sources/Sub2APIMonitorApp/Models/MenuBarTab.swift Sources/Sub2APIMonitorApp/Models/DashboardSubtab.swift Sources/Sub2APIMonitorApp/Preview/MockFixtures.swift Tests/Sub2APIMonitorTests/AppModelFilterTests.swift
git commit -m "feat(state): 补齐菜单栏页签与仪表盘状态"
```

### Task 3: Rebuild The Account Monitor Tab For The Narrow Popup

**Files:**
- Create: `Sources/Sub2APIMonitorApp/UI/AccountMonitorTabView.swift`
- Modify: `Sources/Sub2APIMonitorApp/UI/MenuBarRootView.swift`
- Modify: `Sources/Sub2APIMonitorApp/UI/SiteSummarySection.swift`
- Modify: `Sources/Sub2APIMonitorApp/UI/FilterChipRow.swift`
- Modify: `Sources/Sub2APIMonitorApp/UI/AccountCardGrid.swift`
- Modify: `Sources/Sub2APIMonitorApp/UI/AccountCardView.swift`
- Modify: `Sources/Sub2APIMonitorApp/UI/ProgressStripe.swift`
- Modify: `Sources/Sub2APIMonitorApp/UI/MenuBarPopupLayout.swift`
- Modify: `Tests/Sub2APIMonitorTests/MenuBarLayoutTests.swift`

- [ ] **Step 1: Write failing layout tests for the compact popup**

```swift
import AppKit
import SwiftUI
import Testing
@testable import Sub2APIMonitorApp

@Test
func menuBarPopupHeightStillClampsAfterAddingTabs() {
    #expect(MenuBarPopupLayout.minimumHeight == 240)
    #expect(MenuBarPopupLayout.maximumHeight == 560)
}

@Test
@MainActor
func menuBarRootViewStillProducesUsefulFittingHeightAtNarrowWidth() {
    let model = AppModel()
    model.summary = SiteSummary(
        siteName: "demo",
        baseURL: URL(string: "https://demo.example.com")!,
        totalAccounts: 2,
        todayTokens: 2_200_000,
        totalTokens: 88_500_000,
        todayActualCost: 11.4,
        todayStandardCost: 16.8,
        totalActualCost: 420.0,
        totalStandardCost: 590.0,
        lastRefreshedAt: .now
    )
    model.cards = [
        AccountCardModel(
            id: 1,
            name: "team-1",
            state: .inUse,
            currentConcurrency: 1,
            lastUsedAt: .now,
            fiveHourUtilization: 0.18,
            fiveHourCountdownText: "4h 20m",
            fiveHourWindowText: "已用 18% · 剩余 82%",
            sevenDayUtilization: 0.42,
            sevenDayCountdownText: "5d 4h",
            sevenDayWindowText: "已用 42% · 剩余 58%"
        ),
        AccountCardModel(
            id: 2,
            name: "team-2",
            state: .tight,
            currentConcurrency: 0,
            lastUsedAt: .now.addingTimeInterval(-900),
            fiveHourUtilization: 0.76,
            fiveHourCountdownText: "18m",
            fiveHourWindowText: "已用 76% · 剩余 24%",
            sevenDayUtilization: 0.82,
            sevenDayCountdownText: "19h",
            sevenDayWindowText: "已用 82% · 剩余 18%"
        )
    ]

    let hostingView = NSHostingView(
        rootView: MenuBarRootView(model: model)
            .frame(width: 410)
    )

    #expect(hostingView.fittingSize.height > 200)
}
```

- [ ] **Step 2: Run the layout tests before changing the popup**

Run: `swift test --filter MenuBarLayoutTests`

Expected: FAIL because the tests assert the new compact popup constraints and the current root view is still a single untabbed scroll stack with a dual-column grid.

- [ ] **Step 3: Replace the grid layout with a compact single-column account monitor**

```swift
struct AccountMonitorTabView: View {
    @Bindable var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SiteSummarySection(summary: model.summary)
            FilterChipRow(selectedFilter: model.selectedFilter) { model.selectedFilter = $0 }
            AccountCardGrid(cards: model.filteredCards)
            Button("在浏览器中打开站点") { model.openSiteHome() }
                .buttonStyle(.bordered)
        }
    }
}

struct AccountCardGrid: View {
    let cards: [AccountCardModel]

    var body: some View {
        LazyVStack(spacing: 8) {
            ForEach(cards) { card in
                AccountCardView(card: card)
            }
        }
    }
}
```

Implementation notes:

- `MenuBarRootView` should become:
  - header
  - top-level tab picker
  - active tab content
- Set popup width target to `410`.
- Keep the popup narrow by:
  - stacking summary content vertically
  - using a single-column list
  - reducing outer padding from the current roomy layout
- `SiteSummarySection` should show:
  - `今日 Token` and `总 Token`
  - token value on the left
  - `实际金额 / 标准金额` on the right
- `ProgressStripe` should show:
  - label
  - percentage
  - countdown
  - compact `windowText`
- `AccountCardView` should fit both `5h` and `7d` blocks without pushing the card beyond about half the viewport height.

- [ ] **Step 4: Re-run layout tests and build**

Run: `swift test --filter MenuBarLayoutTests`

Expected: PASS with the new fitting-height baseline and popup clamp values.

Run: `swift build`

Expected: PASS with no SwiftUI type-checking regressions.

- [ ] **Step 5: Commit**

```bash
git add Sources/Sub2APIMonitorApp/UI/AccountMonitorTabView.swift Sources/Sub2APIMonitorApp/UI/MenuBarRootView.swift Sources/Sub2APIMonitorApp/UI/SiteSummarySection.swift Sources/Sub2APIMonitorApp/UI/FilterChipRow.swift Sources/Sub2APIMonitorApp/UI/AccountCardGrid.swift Sources/Sub2APIMonitorApp/UI/AccountCardView.swift Sources/Sub2APIMonitorApp/UI/ProgressStripe.swift Sources/Sub2APIMonitorApp/UI/MenuBarPopupLayout.swift Tests/Sub2APIMonitorTests/MenuBarLayoutTests.swift
git commit -m "feat(ui): 重构窄弹层账号监控页"
```

### Task 4: Add The Native Dashboard Tab

**Files:**
- Create: `Sources/Sub2APIMonitorApp/UI/DashboardTabView.swift`
- Create: `Sources/Sub2APIMonitorApp/UI/DashboardSummaryStrip.swift`
- Create: `Sources/Sub2APIMonitorApp/UI/DashboardModelList.swift`
- Create: `Sources/Sub2APIMonitorApp/UI/DashboardUserRankingList.swift`
- Modify: `Sources/Sub2APIMonitorApp/UI/MenuBarRootView.swift`
- Modify: `Sources/Sub2APIMonitorApp/Preview/MockFixtures.swift`
- Modify: `Tests/Sub2APIMonitorTests/DashboardAggregatorTests.swift`

- [ ] **Step 1: Add failing tests for the mapped dashboard content**

```swift
import Testing
@testable import Sub2APIMonitorApp

@Test
func aggregatorBuildsDashboardModelRowsInDescendingRatioOrder() {
    let site = SiteConfiguration(
        name: "demo",
        baseURL: URL(string: "https://demo.example.com")!,
        adminToken: "token"
    )
    let dashboardStats = AdminDashboardStatsDTO(
        totalAccounts: 0,
        todayTokens: 100,
        totalTokens: 200,
        todayCost: 1.2,
        todayActualCost: 0.9,
        totalCost: 4.8,
        totalActualCost: 3.6
    )
    let snapshot = AdminDashboardSnapshotDTO(
        stats: nil,
        models: [
            AdminDashboardModelDTO(model: "gpt-4.1", tokens: 40, actualCost: 1.0, ratio: 0.20),
            AdminDashboardModelDTO(model: "gpt-4.1-mini", tokens: 124, actualCost: 2.2, ratio: 0.62)
        ],
        usersTrend: []
    )

    let payload = DashboardAggregator().build(
        site: site,
        dashboardStats: dashboardStats,
        dashboardSnapshot: snapshot,
        accounts: [],
        usages: [:]
    )

    #expect(payload.dashboardModels.map(\.modelName) == ["gpt-4.1-mini", "gpt-4.1"])
}

@Test
func aggregatorKeepsTopUsersSortedByActualCostDescending() {
    let site = SiteConfiguration(
        name: "demo",
        baseURL: URL(string: "https://demo.example.com")!,
        adminToken: "token"
    )
    let dashboardStats = AdminDashboardStatsDTO(
        totalAccounts: 0,
        todayTokens: 100,
        totalTokens: 200,
        todayCost: 1.2,
        todayActualCost: 0.9,
        totalCost: 4.8,
        totalActualCost: 3.6
    )
    let snapshot = AdminDashboardSnapshotDTO(
        stats: nil,
        models: [],
        usersTrend: [
            AdminDashboardUserRankingDTO(name: "team-a", tokens: 410_000, actualCost: 3.1, standardCost: 4.0, primaryModel: "gpt-4.1"),
            AdminDashboardUserRankingDTO(name: "team-b", tokens: 820_000, actualCost: 8.4, standardCost: 10.5, primaryModel: "gpt-4.1-mini")
        ]
    )

    let payload = DashboardAggregator().build(
        site: site,
        dashboardStats: dashboardStats,
        dashboardSnapshot: snapshot,
        accounts: [],
        usages: [:]
    )

    #expect(payload.dashboardUserRanking.map(\.displayName) == ["team-b", "team-a"])
}
```

- [ ] **Step 2: Run the dashboard tests before adding the tab views**

Run: `swift test --filter DashboardAggregatorTests`

Expected: FAIL because `DashboardPayload` does not yet expose mapped dashboard rows.

- [ ] **Step 3: Implement the native dashboard tab and subtab switcher**

```swift
struct DashboardTabView: View {
    @Bindable var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            DashboardSummaryStrip(summary: model.summary, primaryModelName: model.primaryModelName)

            Picker("仪表盘内容", selection: $model.selectedDashboardSubtab) {
                Text("模型分布").tag(DashboardSubtab.models)
                Text("用户消费榜").tag(DashboardSubtab.users)
            }
            .pickerStyle(.segmented)

            if model.selectedDashboardSubtab == .models {
                DashboardModelList(items: model.dashboardModels)
            } else {
                DashboardUserRankingList(items: model.dashboardUserRanking)
            }
        }
    }
}
```

Implementation notes:

- `DashboardSummaryStrip` should show:
  - 今日实际金额
  - 今日标准金额
  - 活跃模型数
  - 主消耗模型
- `DashboardModelList` rows should show:
  - model name
  - ratio
  - tokens
  - actual cost
- `DashboardUserRankingList` rows should show:
  - rank
  - display name
  - 今日金额
  - 今日 token
  - primary model
- Keep everything vertically stacked to preserve the narrow popup width.

- [ ] **Step 4: Re-run tests and build**

Run: `swift test --filter DashboardAggregatorTests`

Expected: PASS with sorted model and user ranking data.

Run: `swift build`

Expected: PASS with the new dashboard SwiftUI files.

- [ ] **Step 5: Commit**

```bash
git add Sources/Sub2APIMonitorApp/UI/DashboardTabView.swift Sources/Sub2APIMonitorApp/UI/DashboardSummaryStrip.swift Sources/Sub2APIMonitorApp/UI/DashboardModelList.swift Sources/Sub2APIMonitorApp/UI/DashboardUserRankingList.swift Sources/Sub2APIMonitorApp/UI/MenuBarRootView.swift Sources/Sub2APIMonitorApp/Preview/MockFixtures.swift Tests/Sub2APIMonitorTests/DashboardAggregatorTests.swift
git commit -m "feat(ui): 添加原生仪表盘页签"
```

### Task 5: Polish The Settings Window And Connection Test Flow

**Files:**
- Create: `Sources/Sub2APIMonitorApp/UI/SettingsTokenGuide.swift`
- Modify: `Sources/Sub2APIMonitorApp/App/AppModel.swift`
- Modify: `Sources/Sub2APIMonitorApp/Networking/AdminAccountsAPI.swift`
- Modify: `Sources/Sub2APIMonitorApp/UI/SettingsView.swift`
- Modify: `Tests/Sub2APIMonitorTests/SettingsStorageSecurityTests.swift`

- [ ] **Step 1: Add failing tests for connection testing and token guidance**

```swift
import Foundation
import Testing
@testable import Sub2APIMonitorApp

@Test
func settingsViewSourceContainsTokenGuideCopy() throws {
    let packageRoot = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
    let sourceURL = packageRoot.appendingPathComponent("Sources/Sub2APIMonitorApp/UI/SettingsView.swift")
    let source = try String(contentsOf: sourceURL, encoding: .utf8)

    #expect(source.contains("不知道在哪找？点击查看获取方式"))
    #expect(source.contains("localStorage.getItem('auth_token')"))
    #expect(source.contains("测试连接"))
}
```

- [ ] **Step 2: Run the settings tests before implementation**

Run: `swift test --filter SettingsStorageSecurityTests`

Expected: FAIL because the new token-guide copy and test-connection affordance are not in `SettingsView` yet.

- [ ] **Step 3: Implement the flat settings card, disclosure guide, and connection test**

```swift
struct SettingsTokenGuide: View {
    @State private var isExpanded = false

    var body: some View {
        DisclosureGroup("不知道在哪找？点击查看获取方式", isExpanded: $isExpanded) {
            VStack(alignment: .leading, spacing: 6) {
                Text("1. 打开 sub2api 管理后台")
                Text("2. 浏览器按 F12 打开控制台")
                Text("3. 执行 localStorage.getItem('auth_token')")
                    .textSelection(.enabled)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }
}
```

Implementation notes:

- Add `AppModel.testConnection()` that:
  - validates `baseURLInput`
  - validates `adminTokenInput`
  - calls `fetchDashboardStats()`
  - updates a dedicated `connectionTestMessage`
- Update `SettingsView` so the bottom action row contains:
  - `测试连接`
  - `保存并刷新`
- Keep the existing no-Keychain storage logic intact.
- Match the popup visual language:
  - thin borders
  - flat white cards
  - teal accent for primary action

- [ ] **Step 4: Re-run tests and build**

Run: `swift test --filter SettingsStorageSecurityTests`

Expected: PASS with the new token-guide copy check and existing no-Keychain assertions.

Run: `swift build`

Expected: PASS with the new settings helper view and connection test flow.

- [ ] **Step 5: Commit**

```bash
git add Sources/Sub2APIMonitorApp/UI/SettingsTokenGuide.swift Sources/Sub2APIMonitorApp/UI/SettingsView.swift Sources/Sub2APIMonitorApp/App/AppModel.swift Sources/Sub2APIMonitorApp/Networking/AdminAccountsAPI.swift Tests/Sub2APIMonitorTests/SettingsStorageSecurityTests.swift
git commit -m "feat(settings): 完善设置页与连接测试"
```

### Task 6: Final Verification And Manual Smoke Check

**Files:**
- Modify: `docs/superpowers/plans/2026-04-09-sub2api-macos-menubar-monitor.md`

- [ ] **Step 1: Run the full automated suite**

Run: `swift test`

Expected: PASS for all existing and newly added tests.

- [ ] **Step 2: Run a clean build**

Run: `swift build`

Expected: PASS with no warnings that indicate missing symbols, ambiguous SwiftUI generics, or broken DTO decoding.

- [ ] **Step 3: Manual smoke check in the app**

Checklist:

- Launch the app and confirm there is only one menu bar icon.
- Open the menu and confirm the popup is still narrow.
- Confirm `账号监控` is the default tab.
- Confirm the summary cards show token on the left and money on the right.
- Confirm at least two account cards are visible without an oversized card layout.
- Confirm each account card shows both `5h` and `7d` progress, countdown, and compact window text.
- Switch to `仪表盘` and verify:
  - `模型分布` appears first
  - `用户消费榜` can be switched to
  - both views remain vertically stacked
- Open settings and verify:
  - `测试连接` works
  - `保存并刷新` still works
  - token guide copy is present
  - no Keychain prompt appears
- Click `在浏览器中打开站点` and verify the browser opens the configured `sub2api` site.

- [ ] **Step 4: Update this plan with any verification notes**

```markdown
- Verified on macOS menu bar popup at 410px width
- Verified no Keychain prompt during save/test flow
- Verified dashboard tab shows models and ranking data from snapshot-v2
```

- [ ] **Step 5: Commit**

```bash
git add docs/superpowers/plans/2026-04-09-sub2api-macos-menubar-monitor.md
git commit -m "docs(plan): 记录最终验证结果"
```

## Self-Review

- Spec coverage:
  - Narrow popup: covered in Task 3 and Task 6
  - Top-level `账号监控 / 仪表盘`: covered in Task 2 and Task 4
  - Summary cards with token plus money: covered in Task 1 and Task 3
  - Compact account cards with `5h / 7d` countdown and window info: covered in Task 1 and Task 3
  - Native dashboard tab with `模型分布 / 用户消费榜`: covered in Task 1, Task 2, and Task 4
  - Settings A-style flow, token guide, test connection, no Keychain: covered in Task 5
  - Browser-only deep handoff: covered in Task 2, Task 3, and Task 6
- Placeholder scan:
  - No `TBD`, `TODO`, or deferred “implement later” wording remains.
- Type consistency:
  - `MenuBarTab.accounts`
  - `DashboardSubtab.models`
  - `DashboardPayload.dashboardModels`
  - `DashboardPayload.dashboardUserRanking`
  - `AccountCardModel.fiveHourWindowText`
  - `AccountCardModel.sevenDayWindowText`
