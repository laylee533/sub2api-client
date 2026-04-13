import SwiftUI

struct MenuBarRootView: View {
    @State private var measuredContentHeight: CGFloat = MenuBarPopupLayout.minimumHeight
    @Bindable var model: AppModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                header

                if let errorMessage = model.errorMessage, !errorMessage.isEmpty {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(10)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.orange.opacity(0.22))
                        )
                }

                if model.hasConfiguration {
                    tabPicker
                    activeContent
                } else {
                    setupState
                }
            }
            .padding(12)
            .background(contentHeightReader)
        }
        .frame(width: 410, height: popupHeight, alignment: .top)
        .background(Color(nsColor: .windowBackgroundColor))
        .onPreferenceChange(MenuBarPopupContentHeightKey.self) { measuredHeight in
            measuredContentHeight = MenuBarPopupLayout.preferredHeight(for: measuredHeight)
        }
        .task {
            await model.loadIfNeeded()
        }
    }

    private var popupHeight: CGFloat {
        MenuBarPopupLayout.preferredHeight(for: measuredContentHeight)
    }

    private var contentHeightReader: some View {
        GeometryReader { proxy in
            Color.clear
                .preference(key: MenuBarPopupContentHeightKey.self, value: proxy.size.height)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                if model.hasConfiguration {
                    Button {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            model.isSitePickerExpanded.toggle()
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Text(model.selectedSiteDisplayName)
                                .font(.headline)
                                .lineLimit(1)
                                .minimumScaleFactor(0.9)
                            Image(systemName: model.isSitePickerExpanded ? "chevron.up" : "chevron.down")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.gray.opacity(0.16))
                        )
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: 180, alignment: .leading)
                } else {
                    Text("未配置站点")
                        .font(.headline)
                }

                Spacer(minLength: 0)

                if model.hasConfiguration {
                    Text("\(model.summary.totalAccounts)")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(Color.white)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.gray.opacity(0.18)))
                }

                HStack(spacing: 8) {
                    if model.isLoading {
                        ProgressView()
                            .controlSize(.small)
                    }

                    Button("设置") {
                        SettingsWindowCoordinator.shared.show(model: model)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)

                    Button("刷新") {
                        Task {
                            await model.refresh()
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .disabled(!model.hasConfiguration || model.isLoading)
                }
            }

            if model.hasConfiguration, model.isSitePickerExpanded {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(model.persistedSites) { site in
                        Button {
                            Task {
                                await model.selectSite(site.id)
                            }
                        } label: {
                            HStack(spacing: 8) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(displayName(for: site))
                                        .font(.subheadline)
                                        .fontWeight(model.selectedSiteID == site.id ? .semibold : .regular)
                                        .foregroundStyle(.primary)
                                    Text(site.baseURLString)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                                Spacer()
                                if model.selectedSiteID == site.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.caption)
                                        .foregroundStyle(.teal)
                                }
                            }
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(model.selectedSiteID == site.id ? Color.teal.opacity(0.08) : Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(8)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.gray.opacity(0.16))
                )
                .frame(maxWidth: 180, alignment: .leading)
            }
        }
    }

    private var tabPicker: some View {
        Picker("", selection: $model.selectedTab) {
            Text("账号监控")
                .tag(MenuBarTab.accounts)
            Text("仪表盘")
                .tag(MenuBarTab.dashboard)
        }
        .labelsHidden()
        .pickerStyle(.segmented)
    }

    @ViewBuilder
    private var activeContent: some View {
        switch model.selectedTab {
        case .accounts:
            AccountMonitorTabView(model: model)
        case .dashboard:
            DashboardTabView(model: model)
        }
    }

    private var setupState: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("先添加一个站点")
                .font(.headline)
            Text("在设置里保存站点地址和 Admin Token，菜单栏就会直接显示账号池状态。")
                .font(.caption)
                .foregroundStyle(.secondary)
            Button {
                SettingsWindowCoordinator.shared.show(model: model)
            } label: {
                Text("打开设置")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.teal)
        }
        .padding(14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.gray.opacity(0.16))
        )
    }

    private func displayName(for site: PersistedSite) -> String {
        let trimmed = site.siteName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            return trimmed
        }

        return URL(string: site.baseURLString)?.host ?? "未命名站点"
    }
}

private struct MenuBarPopupContentHeightKey: PreferenceKey {
    static let defaultValue: CGFloat = MenuBarPopupLayout.minimumHeight

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}
