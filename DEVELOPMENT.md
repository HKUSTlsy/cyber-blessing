# 开发与验证

本文面向修改源码和自行打包的开发者。普通用户请先看 [安装与使用指南](README.md)。

## 环境与运行

- macOS 13 或更新版本。
- Swift 5.9+，macOS Command Line Tools 可构建并运行独立核心检查。
- 完整 XCTest 和 Xcode 调试需要包含相应测试框架的完整 Xcode。
- 双架构包包含 Apple Silicon arm64 与 Intel x86_64；当前机器的实际运行验证仅覆盖 arm64。

首次构建前安装 Apple Command Line Tools（若已有完整 Xcode，可使用其工具链）：

```bash
xcode-select --install
```

获取最新源码并进入项目目录：

```bash
git clone https://github.com/HKUSTlsy/cyber-blessing.git
cd cyber-blessing
```

从源码启动应用，之后点击菜单栏火焰图标；关闭应用后运行检查：

```bash
swift run CyberBlessing
./scripts/check.sh
```

也可在 Xcode 打开 `Package.swift`，选择 `CyberBlessing` scheme。完整测试环境运行 `swift test`；仅有 Command Line Tools 时使用 `swift run CyberBlessingChecks`，运行相同的 28 项回归检查，无需安装额外依赖。

不要搬运编译缓存到另一个目录。若旧项目包含失效的 `.build`，先将其移走再构建。源码 ZIP 不包含 `.build`、`.work` 或交付包。

## 版本与打包

唯一版本来源为 `Sources/CyberBlessing/Resources/VERSION`，界面与包信息均读取该版本。

```bash
./scripts/package-macos.sh
./scripts/verify-package.sh
```

可传入与 VERSION 一致的版本号和输出目录，例如 `./scripts/package-macos.sh 0.7.4 dist`；不一致时脚本立即报错。脚本采用独立构建目录，迁移项目后会自动退役旧打包缓存。

输出包括应用、双架构 macOS ZIP、源码 ZIP 及对应 SHA-256 文件。发布前检查版本、架构、全部素材、图标与签名，并验证 ZIP 解包后的应用。之前的默认应用移入 `dist/archive-*`，已有历史版本 ZIP 保留。

```bash
cd dist
shasum -a 256 -c CyberBlessing-0.7.4-macOS.zip.sha256
shasum -a 256 -c CyberBlessing-0.7.4-source.zip.sha256
```

本地打包使用 ad-hoc 签名，不包含 Developer ID 签名或 Apple 公证。可以发布未公证包，但从浏览器下载后首次运行通常需要用户手动放行；具体步骤见 [安装指南](README.md#首次打开未公证版本)。要通过默认 Gatekeeper 检查，需要另行完成 Developer ID 签名和 Apple 公证。

## 应用检查与证据

诊断模式使用独立的临时 UserDefaults，不改变用户数据。它验证真实控制器的连击、任务取消、点香阶段、实际嵌入的原生 NSEvent 滚轮输入、音效并发、资源加载，并保存四项功能、设置、点香各阶段和不同结果的原生渲染截图及 JSON 结果：

```bash
dist/CyberBlessing.app/Contents/MacOS/CyberBlessing --self-check .work/app-qa
```

该检查覆盖原生离屏渲染，不替代菜单栏真实点击、快捷键路由、VoiceOver、macOS 13 和 Intel 机器上的人工验收。

发布检查与已知验证边界见 [RELEASE_CHECK.md](RELEASE_CHECK.md)。

素材来源和图标再生成方法见 [ASSETS.md](ASSETS.md) 和 [ASSETS_0.7.0.md](ASSETS_0.7.0.md)；界面说明见 [DESIGN.md](DESIGN.md)。项目采用 [MIT License](LICENSE)。
