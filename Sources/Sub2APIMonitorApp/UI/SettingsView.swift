import SwiftUI

struct SettingsView: View {
    private enum Field: Hashable {
        case siteName
        case baseURL
        case adminToken
    }

    @FocusState private var focusedField: Field?
    @Bindable var model: AppModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("站点设置")
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text("这里管理多个 sub2api 站点。菜单栏顶部会默认收起，点击后以下拉形式切换当前站点。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                settingsSection(title: "已保存站点") {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(model.persistedSites) { site in
                            Button {
                                model.beginEditingSite(site.id)
                            } label: {
                                HStack(spacing: 10) {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(displayName(for: site))
                                            .font(.subheadline)
                                            .fontWeight(site.id == model.editingSiteID ? .semibold : .regular)
                                            .foregroundStyle(.primary)
                                        Text(site.baseURLString)
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(1)
                                    }

                                    Spacer()

                                    if site.id == model.selectedSiteID {
                                        Text("当前")
                                            .font(.caption2)
                                            .padding(.horizontal, 7)
                                            .padding(.vertical, 4)
                                            .background(Color.teal.opacity(0.12))
                                            .foregroundStyle(.teal)
                                            .clipShape(Capsule())
                                    }
                                }
                                .padding(10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(site.id == model.editingSiteID ? Color.teal.opacity(0.08) : Color(nsColor: .controlBackgroundColor))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }

                        Button {
                            model.beginAddingSite()
                        } label: {
                            Label("新增站点", systemImage: "plus")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                }

                settingsSection(title: "编辑站点") {
                    inputBlock(
                        title: "站点名称（可选）",
                        prompt: "例如：生产站 / 备用站",
                        text: $model.siteNameInput,
                        field: .siteName,
                        secure: false
                    )
                    inputBlock(
                        title: "站点地址",
                        prompt: "例如：https://your-sub2api.example.com",
                        text: $model.baseURLInput,
                        field: .baseURL,
                        secure: false
                    )

                    Text("未填写协议时会默认补成 https://")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if let normalizedBaseURLPreview {
                        Text("实际站点根地址：\(normalizedBaseURLPreview)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                    }

                    inputBlock(
                        title: "Admin Token",
                        prompt: "粘贴浏览器 localStorage 里的 auth_token",
                        text: $model.adminTokenInput,
                        field: .adminToken,
                        secure: true
                    )

                    SettingsTokenGuide()

                    Text("Token 仅保存在本地配置中，不会写入钥匙串。")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if let dashboardEndpointPreview {
                        Text("测试请求：\(dashboardEndpointPreview)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                    }

                    if model.canDeleteEditingSite {
                        Button(role: .destructive) {
                            Task {
                                await model.deleteEditingSite()
                            }
                        } label: {
                            Text("删除站点")
                        }
                        .buttonStyle(.bordered)
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 10) {
                        Button("测试连接") {
                            Task {
                                await model.testConnection()
                            }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .disabled(model.isLoading)

                        Button {
                            Task {
                                await model.saveSettings()
                            }
                        } label: {
                            HStack(spacing: 8) {
                                if model.isLoading {
                                    ProgressView()
                                        .controlSize(.small)
                                }
                                Text(model.isLoading ? "刷新中..." : "保存并刷新")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color.teal)
                        .disabled(model.isLoading)
                    }

                    statusMessage(text: model.connectionTestMessage)
                    statusMessage(text: model.settingsMessage)
                }
            }
            .padding(22)
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear {
            DispatchQueue.main.async {
                if model.baseURLInput.isEmpty {
                    focusedField = .baseURL
                } else if model.adminTokenInput.isEmpty {
                    focusedField = .adminToken
                } else {
                    focusedField = .siteName
                }
            }
        }
    }

    private var normalizedBaseURLPreview: String? {
        model.normalizedBaseURLPreview
    }

    private var dashboardEndpointPreview: String? {
        model.dashboardEndpointPreview
    }

    @ViewBuilder
    private func settingsSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)

            VStack(alignment: .leading, spacing: 12) {
                content()
            }
            .padding(16)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.gray.opacity(0.12))
            )
        }
    }

    @ViewBuilder
    private func inputBlock(
        title: String,
        prompt: String,
        text: Binding<String>,
        field: Field,
        secure: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)

            if secure {
                SecureField(prompt, text: text)
                    .focused($focusedField, equals: field)
                    .textFieldStyle(.roundedBorder)
            } else {
                TextField(prompt, text: text)
                    .focused($focusedField, equals: field)
                    .textFieldStyle(.roundedBorder)
            }
        }
    }

    @ViewBuilder
    private func statusMessage(text: String?) -> some View {
        if let text, !text.isEmpty {
            Text(text)
                .font(.caption)
                .foregroundStyle(messageColor(for: text))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func messageColor(for message: String) -> Color {
        if let errorMessage = model.errorMessage, errorMessage == message {
            return .red
        }
        return .secondary
    }

    private func displayName(for site: PersistedSite) -> String {
        let trimmed = site.siteName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            return trimmed
        }
        return URL(string: site.baseURLString)?.host ?? "未命名站点"
    }
}
