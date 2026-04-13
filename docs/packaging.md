# Packaging Guide

## 目标

为 `Sub2APIMonitorApp` 生成一个本地可分发的 `dmg`。

## 推荐命令

```bash
./scripts/package-dmg.sh
```

## 脚本行为

脚本会：

1. 执行 `swift build -c release`
2. 运行 `scripts/generate-icons.swift` 生成像素风 `AppIcon.icns`
3. 从 release 二进制生成 `Sub2APIMonitorApp.app`
4. 写入带 `CFBundleIconFile` 的最小 `Info.plist`
5. 对 `.app` 做 ad-hoc `codesign`
6. 创建带 `Applications` 快捷方式的 `dmg`

## 输出目录

```text
dist/
  Sub2APIMonitorApp.app
  Sub2APIMonitorApp.dmg
```

## 说明

- 当前 `dmg` 为本地分发产物，不包含公证
- 在其他 Mac 上首次打开时，系统可能仍会提示来源校验
- 如果后续需要正式对外分发，可以在此基础上增加 Developer ID 签名和 notarization
