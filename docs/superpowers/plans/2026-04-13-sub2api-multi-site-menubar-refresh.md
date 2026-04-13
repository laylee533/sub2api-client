# Sub2API Multi-Site Menu Bar Refresh Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add multi-site support, restore the narrow menu bar popup, and align account/dashboard data presentation with the approved design.

**Architecture:** Keep `AppModel` as the single observable UI state, upgrade persisted settings from one site to a site list plus selected site ID, map richer account payloads into compact popup cards, and keep the popup and settings surfaces visually flat and menu-bar sized. Reuse current networking and aggregation paths, but change them to prefer account `extra.codex_5h_* / codex_7d_*` fields over per-account usage requests when available.

**Tech Stack:** Swift 6, SwiftUI, Observation, Foundation, AppKit, UserDefaults, URLSession, async/await, Swift Testing

---

## Delta Scope

- Keep the existing macOS app shell and current menu bar entry point
- Replace single-site persistence with multi-site persistence
- Replace the popup header with a collapsed site switcher dropdown
- Remove dashboard user ranking from the popup
- Make account cards shorter while still showing model info and both usage windows
- Keep settings storage local only, with no Keychain use

## Planned File Structure

- Create: `Sources/Sub2APIMonitorApp/Models/PersistedSite.swift`
- Modify: `Sources/Sub2APIMonitorApp/App/AppModel.swift`
- Modify: `Sources/Sub2APIMonitorApp/Models/AdminAccountDTO.swift`
- Modify: `Sources/Sub2APIMonitorApp/Models/AccountCardModel.swift`
- Modify: `Sources/Sub2APIMonitorApp/Models/AccountUsageInfoDTO.swift`
- Modify: `Sources/Sub2APIMonitorApp/Models/FilterMode.swift`
- Modify: `Sources/Sub2APIMonitorApp/Networking/AdminAccountsAPI.swift`
- Modify: `Sources/Sub2APIMonitorApp/Networking/SiteConfiguration.swift`
- Modify: `Sources/Sub2APIMonitorApp/Preview/MockFixtures.swift`
- Modify: `Sources/Sub2APIMonitorApp/Services/DashboardAggregator.swift`
- Modify: `Sources/Sub2APIMonitorApp/Services/SettingsStorage.swift`
- Modify: `Sources/Sub2APIMonitorApp/UI/AccountCardGrid.swift`
- Modify: `Sources/Sub2APIMonitorApp/UI/AccountCardView.swift`
- Modify: `Sources/Sub2APIMonitorApp/UI/AccountMonitorTabView.swift`
- Modify: `Sources/Sub2APIMonitorApp/UI/DashboardSummaryStrip.swift`
- Modify: `Sources/Sub2APIMonitorApp/UI/DashboardTabView.swift`
- Modify: `Sources/Sub2APIMonitorApp/UI/FilterChipRow.swift`
- Modify: `Sources/Sub2APIMonitorApp/UI/MenuBarPopupLayout.swift`
- Modify: `Sources/Sub2APIMonitorApp/UI/MenuBarRootView.swift`
- Modify: `Sources/Sub2APIMonitorApp/UI/ProgressStripe.swift`
- Modify: `Sources/Sub2APIMonitorApp/UI/SettingsView.swift`
- Modify: `Sources/Sub2APIMonitorApp/UI/SiteSummarySection.swift`
- Modify: `Tests/Sub2APIMonitorTests/AccountSortingTests.swift`
- Modify: `Tests/Sub2APIMonitorTests/AppModelFilterTests.swift`
- Modify: `Tests/Sub2APIMonitorTests/DashboardAggregatorTests.swift`
- Modify: `Tests/Sub2APIMonitorTests/MenuBarLayoutTests.swift`
- Modify: `Tests/Sub2APIMonitorTests/SettingsStorageSecurityTests.swift`

### Task 1: Multi-Site Persistence And App State

**Files:**
- Create: `Sources/Sub2APIMonitorApp/Models/PersistedSite.swift`
- Modify: `Sources/Sub2APIMonitorApp/App/AppModel.swift`
- Modify: `Sources/Sub2APIMonitorApp/Networking/SiteConfiguration.swift`
- Modify: `Sources/Sub2APIMonitorApp/Services/SettingsStorage.swift`
- Modify: `Tests/Sub2APIMonitorTests/SettingsStorageSecurityTests.swift`

- [ ] **Step 1: Write failing persistence tests for multi-site storage**
- [ ] **Step 2: Run `swift test --filter SettingsStorageSecurityTests` and confirm failure**
- [ ] **Step 3: Add `PersistedSite` plus `sites[] + selectedSiteID` storage format while keeping local-only UserDefaults storage**
- [ ] **Step 4: Extend `AppModel` with selected site state, dropdown state, editable site list state, and site switching refresh logic**
- [ ] **Step 5: Re-run `swift test --filter SettingsStorageSecurityTests` until green**

### Task 2: Account Data Mapping And Sorting

**Files:**
- Modify: `Sources/Sub2APIMonitorApp/Models/AdminAccountDTO.swift`
- Modify: `Sources/Sub2APIMonitorApp/Models/AccountCardModel.swift`
- Modify: `Sources/Sub2APIMonitorApp/Models/AccountUsageInfoDTO.swift`
- Modify: `Sources/Sub2APIMonitorApp/Networking/AdminAccountsAPI.swift`
- Modify: `Sources/Sub2APIMonitorApp/Preview/MockFixtures.swift`
- Modify: `Sources/Sub2APIMonitorApp/Services/DashboardAggregator.swift`
- Modify: `Tests/Sub2APIMonitorTests/AccountSortingTests.swift`
- Modify: `Tests/Sub2APIMonitorTests/DashboardAggregatorTests.swift`

- [ ] **Step 1: Write failing tests for `extra.codex_5h_* / codex_7d_*` preference, model text mapping, and unavailable-last sorting**
- [ ] **Step 2: Run `swift test --filter DashboardAggregatorTests` and `swift test --filter AccountSortingTests` and confirm failure**
- [ ] **Step 3: Decode account `extra` usage snapshot fields and optional model display fields**
- [ ] **Step 4: Prefer account `extra` usage values, fall back to `/usage`, and build compact `5h / 7d` summary strings plus model text on cards**
- [ ] **Step 5: Re-run the two targeted test groups until green**

### Task 3: Narrow Popup UI Refresh

**Files:**
- Modify: `Sources/Sub2APIMonitorApp/UI/AccountCardGrid.swift`
- Modify: `Sources/Sub2APIMonitorApp/UI/AccountCardView.swift`
- Modify: `Sources/Sub2APIMonitorApp/UI/AccountMonitorTabView.swift`
- Modify: `Sources/Sub2APIMonitorApp/UI/DashboardSummaryStrip.swift`
- Modify: `Sources/Sub2APIMonitorApp/UI/DashboardTabView.swift`
- Modify: `Sources/Sub2APIMonitorApp/UI/FilterChipRow.swift`
- Modify: `Sources/Sub2APIMonitorApp/UI/MenuBarPopupLayout.swift`
- Modify: `Sources/Sub2APIMonitorApp/UI/MenuBarRootView.swift`
- Modify: `Sources/Sub2APIMonitorApp/UI/ProgressStripe.swift`
- Modify: `Sources/Sub2APIMonitorApp/UI/SiteSummarySection.swift`
- Modify: `Tests/Sub2APIMonitorTests/MenuBarLayoutTests.swift`

- [ ] **Step 1: Write failing layout tests for the restored narrow popup bounds**
- [ ] **Step 2: Run `swift test --filter MenuBarLayoutTests` and confirm failure**
- [ ] **Step 3: Rebuild the popup header as a collapsed site dropdown, remove the extra title text, and keep the popup width stable**
- [ ] **Step 4: Compress the account cards to show two on first screen, keep token/cost summary readable, and remove dashboard user ranking UI**
- [ ] **Step 5: Re-run `swift test --filter MenuBarLayoutTests` until green**

### Task 4: Multi-Site Settings Window

**Files:**
- Modify: `Sources/Sub2APIMonitorApp/UI/SettingsView.swift`
- Modify: `Sources/Sub2APIMonitorApp/App/AppModel.swift`
- Modify: `Tests/Sub2APIMonitorTests/SettingsStorageSecurityTests.swift`

- [ ] **Step 1: Write failing tests that lock token guidance, local-only storage, and multi-site editing affordances**
- [ ] **Step 2: Run `swift test --filter SettingsStorageSecurityTests` and confirm failure**
- [ ] **Step 3: Replace the single-site form with flat multi-site list + current-site editor + test/save actions**
- [ ] **Step 4: Keep the token guide and add a clear “测试连接” path for the selected site editor**
- [ ] **Step 5: Re-run `swift test --filter SettingsStorageSecurityTests` until green**

### Task 5: Final Regression

**Files:**
- Modify: `Tests/Sub2APIMonitorTests/AppModelFilterTests.swift`
- Test: `Tests/Sub2APIMonitorTests/*`

- [ ] **Step 1: Add or update filter tests to reflect the final card model shape and abnormal filter semantics**
- [ ] **Step 2: Run `swift test --filter AppModelFilterTests`**
- [ ] **Step 3: Run `swift test`**
- [ ] **Step 4: Run `swift build`**
- [ ] **Step 5: Record any manual smoke gaps before closing the task**

## Self-Review

- Spec coverage:
  - Multi-site support: Task 1 + Task 4
  - Dropdown site selector: Task 3
  - Narrow popup width and shorter cards: Task 3
  - `5h / 7d` parity with web: Task 2
  - Remove dashboard user ranking: Task 3
  - No Keychain: Task 1 + Task 4
- Placeholder scan:
  - No `TODO`, `TBD`, or “later” placeholders remain
- Type consistency:
  - App state changes originate in `AppModel`
  - Account usage precedence lives in `DashboardAggregator`
  - Persistent structure changes stay in `SettingsStorage`
