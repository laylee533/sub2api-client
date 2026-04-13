import SwiftUI

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
            .padding(.top, 6)
        }
        .font(.caption)
    }
}
