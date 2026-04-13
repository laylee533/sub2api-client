# Sub2API Pixel Icon Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 为菜单栏应用补齐像素风 App 图标和单色模板菜单栏图标，并让 DMG 打包产物正确带出图标。

**Architecture:** 使用一份 Swift 图标生成脚本输出 macOS `.iconset/.icns`，保证 App 图标可重复生成；菜单栏图标直接用 SwiftUI 像素块视图绘制，避免额外运行时资源装载与模板渲染不稳定。打包脚本负责把 `.icns` 注入 `.app` bundle，并保留现有 `SwiftPM + 自定义 DMG` 流程。

**Tech Stack:** Swift 6, SwiftUI, AppKit, Swift Package Manager, macOS iconutil

---

### Task 1: 建立图标生成产物与打包接入

**Files:**
- Create: `scripts/generate-icons.swift`
- Create: `Resources/AppIcon.icns`
- Modify: `scripts/package-dmg.sh`
- Test: `dist/Sub2APIMonitorApp.app/Contents/Info.plist`

- [ ] **Step 1: 写入图标生成脚本**

```swift
import AppKit
import Foundation

struct PixelRect {
    let x: Int
    let y: Int
    let width: Int
    let height: Int
    let color: NSColor
}

let background = NSColor(calibratedRed: 0.863, green: 0.902, blue: 0.925, alpha: 1)
let frameDark = NSColor(calibratedRed: 0.059, green: 0.090, blue: 0.165, alpha: 1)
let frame = NSColor(calibratedRed: 0.200, green: 0.271, blue: 0.333, alpha: 1)
let screen = NSColor(calibratedRed: 0.055, green: 0.169, blue: 0.129, alpha: 1)
let green = NSColor(calibratedRed: 0.204, green: 0.827, blue: 0.600, alpha: 1)
let greenDim = NSColor(calibratedRed: 0.063, green: 0.725, blue: 0.506, alpha: 1)
let amber = NSColor(calibratedRed: 0.961, green: 0.620, blue: 0.043, alpha: 1)
```

- [ ] **Step 2: 运行脚本生成 `.iconset` 与 `.icns`**

Run: `swift scripts/generate-icons.swift`  
Expected: 生成 `Resources/AppIcon.icns`，并输出 iconset 目录路径

- [ ] **Step 3: 修改 DMG 打包脚本注入图标**

```zsh
swift "$ROOT_DIR/scripts/generate-icons.swift"
mkdir -p "$CONTENTS_DIR/Resources"
cp "$ROOT_DIR/Resources/AppIcon.icns" "$CONTENTS_DIR/Resources/Sub2APIMonitorApp.icns"
```

并在 `Info.plist` 增加：

```xml
<key>CFBundleIconFile</key>
<string>Sub2APIMonitorApp</string>
```

- [ ] **Step 4: 运行打包脚本验证 bundle 内包含图标**

Run: `./scripts/package-dmg.sh`  
Expected: `dist/Sub2APIMonitorApp.app/Contents/Resources/Sub2APIMonitorApp.icns` 存在，`Info.plist` 含 `CFBundleIconFile`

### Task 2: 替换菜单栏入口为像素模板图标

**Files:**
- Create: `Sources/Sub2APIMonitorApp/UI/MenuBarStatusIcon.swift`
- Modify: `Sources/Sub2APIMonitorApp/Sub2APIMonitorApp.swift`
- Modify: `Sources/Sub2APIMonitorApp/App/AppModel.swift`
- Test: `Tests/Sub2APIMonitorTests/MenuBarLayoutTests.swift`

- [ ] **Step 1: 为菜单栏图标补一个稳定的状态枚举**

```swift
enum StatusItemIconMode: Equatable {
    case setup
    case configured
}
```

在 `AppModel` 中提供：

```swift
var statusItemIconMode: StatusItemIconMode {
    hasConfiguration ? .configured : .setup
}
```

- [ ] **Step 2: 新增像素模板图标视图**

```swift
struct MenuBarStatusIcon: View {
    let mode: StatusItemIconMode

    var body: some View {
        PixelIconCanvas(rects: mode == .configured ? Self.configuredRects : Self.setupRects)
            .frame(width: 18, height: 14)
            .foregroundStyle(.primary)
            .accessibilityLabel("sub2api 监控器")
    }
}
```

- [ ] **Step 3: 用自定义图标替换 `systemImage`**

```swift
MenuBarExtra {
    MenuBarRootView(model: model)
} label: {
    MenuBarStatusIcon(mode: model.statusItemIconMode)
}
```

- [ ] **Step 4: 更新测试，验证配置完成后图标模式在刷新生命周期内稳定**

Run: `swift test --filter MenuBarLayoutTests`  
Expected: 菜单栏布局测试通过

### Task 3: 回归验证与文档同步

**Files:**
- Modify: `README.md`
- Modify: `docs/packaging.md`
- Test: `Tests/Sub2APIMonitorTests/*.swift`

- [ ] **Step 1: 补充图标生成/打包说明**

```markdown
`./scripts/package-dmg.sh` 现在会自动生成 App 图标并写入 `.app` bundle。
```

- [ ] **Step 2: 执行完整验证**

Run:

```bash
swift test
swift build
./scripts/package-dmg.sh
```

Expected:

```text
测试通过
构建通过
dist/Sub2APIMonitorApp.app 与 dist/Sub2APIMonitorApp.dmg 生成成功
```

- [ ] **Step 3: 人工检查最终产物**

Run:

```bash
find dist/Sub2APIMonitorApp.app/Contents -maxdepth 2 -type f | sort
```

Expected: 可见 `Resources/Sub2APIMonitorApp.icns` 与主执行文件
