# sub2api-client

一个基于 `Swift + SwiftUI` 的 `sub2api` macOS 菜单栏监控应用。

它的定位不是替代网页后台，而是在菜单栏里快速看：

- 当前站点的 `今日 Token / 总 Token / 金额`
- 账号池里哪些账号正在使用
- 哪些账号的 `5h / 7d` 容量接近上限
- 多个 `sub2api` 站点之间的快速切换

## 当前能力

- 菜单栏弹层主入口
- 多站点本地保存与切换
- 顶部站点下拉，默认收起
- 扁平化、窄宽度弹层布局
- 账号卡片按“正在使用优先、不可用靠后”排序
- 账号卡展示模型信息、`5h / 7d` 进度、倒计时和窗口摘要
- 仪表盘展示金额摘要和模型分布
- 设置页支持 `测试连接`、`保存并刷新`
- 本地存储配置，不使用 Keychain

## 技术栈

- Swift 6
- SwiftUI
- Observation
- Swift Package Manager
- macOS 14+

## 本地开发

### 1. 安装依赖

需要本机已安装 Xcode，并执行：

```bash
xcode-select -p
```

返回结果应类似：

```bash
/Applications/Xcode.app/Contents/Developer
```

### 2. 运行测试

```bash
swift test
```

### 3. 调试运行

可以直接用 Xcode 打开仓库根目录，然后运行 `Sub2APIMonitorApp` scheme。

也可以先命令行构建：

```bash
swift build
```

## 打包 DMG

仓库内提供了打包脚本：

```bash
./scripts/package-dmg.sh
```

脚本会做这些事：

1. 执行 `swift build -c release`
2. 生成像素风 `AppIcon.icns`
3. 生成 `Sub2APIMonitorApp.app`
4. 做 ad-hoc `codesign`
5. 在 `dist/` 下生成 `dmg`

默认产物路径：

- `dist/Sub2APIMonitorApp.app`
- `dist/Sub2APIMonitorApp.dmg`

更详细的打包说明见 [docs/packaging.md](docs/packaging.md)。

## 配置说明

首次运行后，在设置页填写：

- 站点名称
- 站点地址
- Admin Token

### Admin Token 获取方式

在 `sub2api` 管理后台网页中：

1. 打开浏览器开发者工具
2. 执行下面这行

```js
localStorage.getItem('auth_token')
```

3. 把返回值粘贴到设置页的 `Admin Token`

## 数据来源

- 站点统计来自 `admin/dashboard/stats`
- 仪表盘模型分布来自 `admin/dashboard/snapshot-v2`
- 账号列表来自 `admin/accounts`
- `5h / 7d` 优先读取账号 `extra.codex_5h_* / codex_7d_*`
- 只有缺失时才回退到单账号 `/usage`

这样做的目的是尽量和网页端保持一致，并避开某些账号窗口接口偶发失败的问题。

## 仓库结构

```text
Sources/Sub2APIMonitorApp/
  App/           应用状态与窗口协调
  Models/        DTO 与展示模型
  Networking/    sub2api 管理端接口访问
  Services/      聚合与本地存储
  UI/            菜单栏弹层与设置页

Tests/Sub2APIMonitorTests/
  过滤、排序、解码、布局、存储相关测试
```

## 验证状态

当前仓库已通过：

```bash
swift test
swift build
```
