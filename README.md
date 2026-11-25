# Clipboard10

面向频繁复制文本的用户，快速找回最近记录和常用片段。仓库包含三个平台的工程。

## 快速开始

- macOS 12+：用 Xcode 打开 `macos/Clipboard10.xcodeproj`，选择 Clipboard10 运行。
- iOS 15+：用 Xcode 打开 `ios/Clipboard10.xcodeproj`。真机运行请把 Team 与 Bundle Identifier 配成自己的签名。
- Windows：安装 Node.js 20+，在 `windows/` 执行 `npm ci`、`npm start`。使用 `npm run dist:win` 生成 x64 便携包。

## 使用示例

在 Windows 复制几句不同的文本，按 `Ctrl+Shift+V` 打开浮窗。在最近列表选择一项即可取回。把常用回复放进收藏区后，退出再打开仍能使用。该版最近记录保存在内存，收藏写入应用数据目录。想用临时目录体验，可在启动前设置 `CLIPBOARD10_DATA_DIR`。

## 代码结构

- `macos/` 和 `ios/` 是原生 Swift 工程，包含各自的剪贴板服务与界面。
- `windows/` 是 Electron 工程，`Sources/` 含主进程、预加载和界面，`tests/` 含行为测试。

## 开发过程

[查看开发历程](DEVELOPMENT.md)

## 许可与使用范围

项目源码采用 MIT。签名、历史剪贴板及既有用户数据均由用户本机管理。
